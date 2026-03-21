"""
gen_kicad7.py — MSP430G2553 Game Boy schematic generator
Target: KiCad 9.0 native format (version 20250114)

Uses KiCad's built-in libraries for: MSP430G2553, 74HC165, LM386, W25Q128JVS.
Generates custom symbols for: 23LC1024 SRAM, connectors, passives, power.

Layout: MSP430G2553 at CENTER. Peripherals radiate outward:
  - OLED connector, SRAM, Flash: above
  - 74HC165 shift register + buttons: left
  - LM386 audio amp + speaker: right
  - Bypass caps: near MCU

Grid rule: ALL positions are integer multiples of G = 2.54 mm.
Coordinate convention:
  Symbol local:    Y-up  (math convention, same as KiCad .kicad_sym files)
  Schematic world: Y-down (screen convention)
  Mapping: world = (cx + lx,  cy - ly)

Run: python3 docs/hardware/scripts/gen_kicad7.py
Output: docs/hardware/schematic/msp430_gameboy.kicad_sch
"""

import re, uuid as _uuid, pathlib

G = 2.54  # 1 grid unit = 100 mil = 2.54 mm

KICAD_SYM = pathlib.Path(
    '/Applications/KiCad/KiCad.app/Contents/SharedSupport/symbols')
OUT_PATH = pathlib.Path(__file__).resolve().parents[1] / \
    'schematic/msp430_gameboy.kicad_sch'


def uid():
    return str(_uuid.uuid4())


# ── Coordinate helpers ─────────────────────────────────────────────────────────

def pw(cx, cy, lx, ly):
    """Convert local (Y-up) pin position to world (Y-down) coords."""
    return (round(cx + lx, 4), round(cy - ly, 4))


def pin_w(comp_pos, pdict, key):
    lx, ly = pdict[key]
    return pw(comp_pos[0], comp_pos[1], lx, ly)


# ── Element accumulators ───────────────────────────────────────────────────────

PLACED, WIRES, LABELS, POWERS, NC = [], [], [], [], []
STUB = G


def _wire(x1, y1, x2, y2):
    return (f'(wire (pts (xy {x1:.4f} {y1:.4f}) (xy {x2:.4f} {y2:.4f}))'
            f' (stroke (width 0) (type default)) (uuid "{uid()}"))')


def _label(net, x, y, rot=0):
    return (f'(label "{net}" (at {x:.4f} {y:.4f} {rot})'
            f' (fields_autoplaced yes)'
            f' (effects (font (size 1.27 1.27)) (justify left))'
            f' (uuid "{uid()}"))')


def _pwr_placed(sym, x, y):
    off = -2.54 if sym == 'VCC' else 2.54
    return (f'(symbol (lib_id "{sym}") (at {x:.4f} {y:.4f} 0)'
            f' (unit 1) (exclude_from_sim no) (in_bom yes) (on_board yes) (dnp no)'
            f' (uuid "{uid()}")'
            f' (property "Reference" "#PWR"'
            f'  (at {x:.4f} {y+off:.4f} 0) (effects (font (size 1.27 1.27)) (hide)))'
            f' (property "Value" "{sym}"'
            f'  (at {x:.4f} {y-off:.4f} 0) (effects (font (size 1.27 1.27)) (hide)))'
            f')')


def _sym_placed(lib_id, cx, cy, ref, val, rot=0):
    return (f'(symbol (lib_id "{lib_id}") (at {cx:.4f} {cy:.4f} {rot})'
            f' (unit 1) (exclude_from_sim no) (in_bom yes) (on_board yes) (dnp no)'
            f' (uuid "{uid()}")'
            f' (property "Reference" "{ref}"'
            f'  (at {cx:.4f} {cy:.4f} 0) (effects (font (size 1.27 1.27)) (hide)))'
            f' (property "Value" "{val}"'
            f'  (at {cx:.4f} {cy:.4f} 0) (effects (font (size 1.27 1.27)) (hide)))'
            f')')


def lbl(net, px, py, rot=0):
    """Net label with stub wire at pin endpoint (px, py)."""
    dirs = {0: (STUB, 0), 180: (-STUB, 0), 90: (0, -STUB), 270: (0, STUB)}
    dx, dy = dirs.get(rot, (0, 0))
    WIRES.append(_wire(px, py, px + dx, py + dy))
    LABELS.append(_label(net, px + dx, py + dy, rot))


def pwr(sym, px, py):
    POWERS.append(_pwr_placed(sym, px, py))


def nc(px, py):
    NC.append(f'(no_connect (at {px:.4f} {py:.4f}) (uuid "{uid()}"))')


def place(lib_id, cx, cy, ref, val, rot=0):
    PLACED.append(_sym_placed(lib_id, cx, cy, ref, val, rot))


# ── KiCad library symbol extractor ────────────────────────────────────────────

def extract_sym(lib_name, sym_name):
    """Extract symbol from .kicad_sym for embedding in schematic lib_symbols.

    Returns (lib_sym_text, pin_by_name, pin_by_num).
    - lib_sym_text: standalone symbol block ready to embed (no 'extends')
    - pin_by_name / pin_by_num: {str: (lx, ly)} in Y-up local convention

    KiCad does NOT support 'extends' inside a schematic's lib_symbols section.
    Symbols that use extends are resolved here: parent's body/pin sub-symbols are
    merged into the child to produce a fully standalone block.
    """
    lib_text = (KICAD_SYM / f'{lib_name}.kicad_sym').read_text()

    def find_block(name):
        target = f'\t(symbol "{name}"'
        idx = lib_text.find(target)
        if idx == -1:
            raise KeyError(f'"{name}" not found in {lib_name}.kicad_sym')
        depth = 0
        for i in range(idx, len(lib_text)):
            if lib_text[i] == '(':
                depth += 1
            elif lib_text[i] == ')':
                depth -= 1
                if depth == 0:
                    return lib_text[idx:i + 1]
        raise ValueError(f'Unclosed parens for "{name}"')

    def parse_pins(block):
        by_name, by_num = {}, {}
        for m in re.finditer(
            r'\(pin\s+\S+\s+\S+\s+\(at\s+([\d.\-]+)\s+([\d.\-]+)\s+\d+\)'
            r'.*?\(name\s+"([^"]*)"\s.*?\(number\s+"([^"]*)"\s',
            block, re.DOTALL
        ):
            lx, ly = float(m.group(1)), float(m.group(2))
            name, num = m.group(3), m.group(4)
            if name:
                by_name[name] = (lx, ly)
            by_num[num] = (lx, ly)
        return by_name, by_num

    def get_properties(block):
        """Extract property/flag lines between outer header and first sub-symbol."""
        first_nl = block.index('\n')
        sub_idx  = block.find('\t\t(symbol "')
        content  = block[first_nl + 1 : sub_idx if sub_idx != -1 else block.rindex('\n')]
        # Strip extends and embedded_fonts — both invalid in schematic lib_symbols
        content  = re.sub(r'\t*\(extends\s+"[^"]+"\)\n?', '', content)
        content  = re.sub(r'\t*\(embedded_fonts\s+[^)]+\)\n?', '', content)
        return content

    def get_sub_syms(block, src_name):
        """Extract (symbol "SRC_NAME_N_M" ...) blocks."""
        blocks, pos = [], 0
        target = f'\t\t(symbol "{src_name}_'
        while True:
            idx = block.find(target, pos)
            if idx == -1:
                break
            depth = 0
            for i in range(idx, len(block)):
                if block[i] == '(':
                    depth += 1
                elif block[i] == ')':
                    depth -= 1
                    if depth == 0:
                        blocks.append(block[idx:i + 1])
                        pos = i + 1
                        break
        return blocks

    def make_standalone(name, props, sub_syms):
        """Assemble a standalone lib_symbols-ready block."""
        subs = '\n'.join(sub_syms)
        return (
            f'  (symbol "{lib_name}:{name}"\n'
            f'{props}'
            f'{subs}\n'
            f'\t)'
        )

    main_block = find_block(sym_name)
    ext_m      = re.search(r'\(extends\s+"([^"]+)"\)', main_block)

    if ext_m:
        parent_name  = ext_m.group(1)
        parent_block = find_block(parent_name)
        by_name, by_num = parse_pins(parent_block)

        # Merge: child's properties + parent's sub-symbols renamed to child
        props    = get_properties(main_block)
        subs_raw = get_sub_syms(parent_block, parent_name)
        subs     = [s.replace(f'"{parent_name}_', f'"{sym_name}_')
                    for s in subs_raw]
        sym_text = make_standalone(sym_name, props, subs)
    else:
        by_name, by_num = parse_pins(main_block)
        props    = get_properties(main_block)
        subs     = get_sub_syms(main_block, sym_name)
        sym_text = make_standalone(sym_name, props, subs)

    return sym_text, by_name, by_num


# ── Custom symbol helpers ──────────────────────────────────────────────────────

def _rect_sym(name, ref_prefix, pins_left, bw=3*G, extra_pins=''):
    """Build a rectangular IC symbol with left-side signal pins.
    pins_left: list of (pin_name, ly_units, pin_num_str, pin_type)
    Returns (sym_text, pin_by_name, pin_by_num).
    """
    PX = bw + G
    BH = (len(pins_left) / 2 + 0.5) * G
    pins_str = ''
    by_name, by_num = {}, {}
    for pname, ly, pnum, ptype in pins_left:
        pins_str += (
            f'      (pin {ptype} line (at {-PX:.4f} {ly:.4f} 0) (length {G:.4f})\n'
            f'        (name "{pname}" (effects (font (size 1.016 1.016))))\n'
            f'        (number "{pnum}" (effects (font (size 1.016 1.016)))))\n'
        )
        key = re.sub(r'[~{{}}]', '', pname)
        by_name[key] = (-PX, ly)
        by_num[pnum]  = (-PX, ly)
    sym_text = (
        f'  (symbol "{name}"\n'
        f'    (in_bom yes) (on_board yes)\n'
        f'    (property "Reference" "{ref_prefix}" (at 0 {BH+2:.4f} 0)\n'
        f'      (effects (font (size 1.27 1.27))))\n'
        f'    (property "Value" "{name}" (at 0 {-(BH+2):.4f} 0)\n'
        f'      (effects (font (size 1.27 1.27))))\n'
        f'    (symbol "{name}_0_1"\n'
        f'      (rectangle (start {-bw:.4f} {BH:.4f}) (end {bw:.4f} {-BH:.4f})\n'
        f'        (stroke (width 0.254) (type default)) (fill (type background))))\n'
        f'    (symbol "{name}_1_1"\n'
        f'{pins_str}'
        f'{extra_pins}'
        f'  ))'
    )
    return sym_text, by_name, by_num


def make_sram_sym():
    """23LC1024-I/P: SPI SRAM, 8-pin DIP. Signals on left, VCC/GND top/bottom."""
    BW, BH = 3*G, 4*G
    PX = BW + G
    pins = [
        ('~{CS}',   3*G,  '1', 'input'),
        ('SO',      2*G,  '2', 'output'),
        ('NC',      1*G,  '3', 'no_connect'),
        ('SI',     -1*G,  '5', 'input'),
        ('SCK',    -2*G,  '6', 'input'),
        ('~{HOLD}',-3*G,  '7', 'input'),
    ]
    by_name, by_num = {}, {}
    pins_str = ''
    for pname, ly, pnum, ptype in pins:
        pins_str += (
            f'      (pin {ptype} line (at {-PX:.4f} {ly:.4f} 0) (length {G:.4f})\n'
            f'        (name "{pname}" (effects (font (size 1.016 1.016))))\n'
            f'        (number "{pnum}" (effects (font (size 1.016 1.016)))))\n'
        )
        key = re.sub(r'[~{}]', '', pname)
        by_name[key] = (-PX, ly)
        by_num[pnum]  = (-PX, ly)
    # VCC top, GND bottom
    pins_str += (
        f'      (pin power_in line (at 0 {BH+G:.4f} 270) (length {G:.4f})\n'
        f'        (name "VCC" (effects (font (size 1.016 1.016))))\n'
        f'        (number "8" (effects (font (size 1.016 1.016)))))\n'
        f'      (pin power_in line (at 0 {-(BH+G):.4f} 90) (length {G:.4f})\n'
        f'        (name "GND" (effects (font (size 1.016 1.016))))\n'
        f'        (number "4" (effects (font (size 1.016 1.016)))))\n'
    )
    by_name['VCC'] = (0, BH+G)
    by_name['GND'] = (0, -(BH+G))
    by_num['8'] = (0, BH+G)
    by_num['4'] = (0, -(BH+G))
    sym_text = (
        f'  (symbol "SRAM_23LC1024"\n'
        f'    (in_bom yes) (on_board yes)\n'
        f'    (property "Reference" "U" (at 0 {BH+3:.4f} 0)\n'
        f'      (effects (font (size 1.27 1.27))))\n'
        f'    (property "Value" "SRAM_23LC1024" (at 0 {-(BH+3):.4f} 0)\n'
        f'      (effects (font (size 1.27 1.27))))\n'
        f'    (symbol "SRAM_23LC1024_0_1"\n'
        f'      (rectangle (start {-BW:.4f} {BH:.4f}) (end {BW:.4f} {-BH:.4f})\n'
        f'        (stroke (width 0.254) (type default)) (fill (type background))))\n'
        f'    (symbol "SRAM_23LC1024_1_1"\n'
        f'{pins_str}'
        f'  ))'
    )
    return sym_text, by_name, by_num


def make_conn_sym(sym_name, pin_names, bw=G):
    """Single-row connector with all pins on left side."""
    n = len(pin_names)
    PX = bw + G
    BH = (n / 2) * G
    pins_str = ''
    by_name, by_num = {}, {}
    for i, pname in enumerate(pin_names):
        ly = (n / 2 - 0.5 - i) * G
        pnum = str(i + 1)
        pins_str += (
            f'      (pin passive line (at {-PX:.4f} {ly:.4f} 0) (length {G:.4f})\n'
            f'        (name "{pname}" (effects (font (size 1.016 1.016))))\n'
            f'        (number "{pnum}" (effects (font (size 1.016 1.016)))))\n'
        )
        by_name[pname] = (-PX, ly)
        by_num[pnum]   = (-PX, ly)
    sym_text = (
        f'  (symbol "{sym_name}"\n'
        f'    (in_bom yes) (on_board yes)\n'
        f'    (property "Reference" "J" (at 0 {BH+2:.4f} 0)\n'
        f'      (effects (font (size 1.27 1.27))))\n'
        f'    (property "Value" "{sym_name}" (at 0 {-(BH+2):.4f} 0)\n'
        f'      (effects (font (size 1.27 1.27))))\n'
        f'    (symbol "{sym_name}_0_1"\n'
        f'      (rectangle (start {-bw:.4f} {BH:.4f}) (end {bw:.4f} {-BH:.4f})\n'
        f'        (stroke (width 0.254) (type default)) (fill (type background))))\n'
        f'    (symbol "{sym_name}_1_1"\n'
        f'{pins_str}'
        f'  ))'
    )
    return sym_text, by_name, by_num


def make_passive_sym(name, ref, L=3.81, style='R'):
    """Vertical 2-pin passive (R or C). L=pin endpoint offset from center."""
    BH = 2.032 if style == 'R' else 0.508
    if style == 'R':
        body = (f'      (rectangle (start {-G:.4f} {BH:.4f}) (end {G:.4f} {-BH:.4f})\n'
                f'        (stroke (width 0.254) (type default)) (fill (type background)))\n')
    else:
        body = (f'      (polyline (pts (xy {-G:.4f} {BH:.4f}) (xy {G:.4f} {BH:.4f}))\n'
                f'        (stroke (width 0.508) (type default)) (fill (type none)))\n'
                f'      (polyline (pts (xy {-G:.4f} {-BH:.4f}) (xy {G:.4f} {-BH:.4f}))\n'
                f'        (stroke (width 0.508) (type default)) (fill (type none)))\n')
    pin_len = L - BH
    sym_text = (
        f'  (symbol "{name}"\n'
        f'    (in_bom yes) (on_board yes)\n'
        f'    (property "Reference" "{ref}" (at {G:.4f} 0 90)\n'
        f'      (effects (font (size 1.27 1.27))))\n'
        f'    (property "Value" "{name}" (at {-G:.4f} 0 90)\n'
        f'      (effects (font (size 1.27 1.27))))\n'
        f'    (symbol "{name}_0_1"\n{body}    )\n'
        f'    (symbol "{name}_1_1"\n'
        f'      (pin passive line (at 0 {L:.4f} 270) (length {pin_len:.4f})\n'
        f'        (name "~" (effects (font (size 1.27 1.27))))\n'
        f'        (number "1" (effects (font (size 1.27 1.27)))))\n'
        f'      (pin passive line (at 0 {-L:.4f} 90) (length {pin_len:.4f})\n'
        f'        (name "~" (effects (font (size 1.27 1.27))))\n'
        f'        (number "2" (effects (font (size 1.27 1.27)))))\n'
        f'  ))'
    )
    by_num = {'1': (0, L), '2': (0, -L)}
    return sym_text, by_num


def make_power_def(name, is_vcc):
    """KiCad 9 power symbol definition (VCC or GND)."""
    if is_vcc:
        body = (f'      (polyline (pts (xy 0 0) (xy 0 {G:.4f}))\n'
                '        (stroke (width 0.254) (type default)) (fill (type none)))\n'
                f'      (polyline (pts (xy {-G:.4f} {G:.4f}) (xy {G:.4f} {G:.4f}))\n'
                '        (stroke (width 0.508) (type default)) (fill (type none)))\n')
        pin_at, val_y = '0 0 270', 2.5
    else:
        body = (f'      (polyline (pts (xy 0 0) (xy 0 {-G:.4f}))\n'
                '        (stroke (width 0.254) (type default)) (fill (type none)))\n'
                f'      (polyline (pts (xy {-G:.4f} {-G:.4f}) (xy {G:.4f} {-G:.4f}))\n'
                '        (stroke (width 0.508) (type default)) (fill (type none)))\n')
        pin_at, val_y = '0 0 90', -2.5
    return (f'  (symbol "{name}"\n    (power) (in_bom yes) (on_board yes)\n'
            f'    (property "Reference" "#PWR" (at 0 0 0)\n'
            f'      (effects (font (size 1.27 1.27)) (hide)))\n'
            f'    (property "Value" "{name}" (at 0 {val_y:.2f} 0)\n'
            f'      (effects (font (size 1.27 1.27))))\n'
            f'    (symbol "{name}_0_1"\n{body}    )\n'
            f'    (symbol "{name}_1_1"\n'
            f'      (pin power_in line (at {pin_at}) (length 0)\n'
            f'        (name "{name}" (effects (font (size 1.27 1.27))))\n'
            f'        (number "1" (effects (font (size 1.27 1.27)))))\n'
            f'  ))')


def make_speaker_sym():
    L = 2 * G
    by_num = {'1': (-L, 0), '2': (L, 0)}
    sym_text = (
        f'  (symbol "Speaker"\n    (in_bom yes) (on_board yes)\n'
        f'    (property "Reference" "LS" (at 0 {2.5:.4f} 0)\n'
        f'      (effects (font (size 1.27 1.27))))\n'
        f'    (property "Value" "Speaker" (at 0 {-2.5:.4f} 0)\n'
        f'      (effects (font (size 1.27 1.27))))\n'
        f'    (symbol "Speaker_0_1"\n'
        f'      (polyline (pts (xy {-G:.4f} {G:.4f}) (xy {-G:.4f} {-G:.4f}))\n'
        '        (stroke (width 0.508) (type default)) (fill (type none)))\n'
        f'      (polyline (pts (xy {-G:.4f} {G:.4f}) (xy {G:.4f} {2*G:.4f})'
        f' (xy {G:.4f} {-2*G:.4f}) (xy {-G:.4f} {-G:.4f}))\n'
        '        (stroke (width 0.254) (type default)) (fill (type none))))\n'
        f'    (symbol "Speaker_1_1"\n'
        f'      (pin passive line (at {-L:.4f} 0 0) (length {G:.4f})\n'
        f'        (name "+" (effects (font (size 1.016 1.016))))\n'
        f'        (number "1" (effects (font (size 1.016 1.016)))))\n'
        f'      (pin passive line (at {L:.4f} 0 180) (length {G:.4f})\n'
        f'        (name "-" (effects (font (size 1.016 1.016))))\n'
        f'        (number "2" (effects (font (size 1.016 1.016)))))\n'
        f'  ))'
    )
    return sym_text, by_num


def make_sw_sym():
    """Horizontal push-button switch, 2-pin."""
    L = G
    by_num = {'1': (-L, 0), '2': (L, 0)}
    sym_text = (
        f'  (symbol "SW_Push"\n    (in_bom yes) (on_board yes)\n'
        f'    (property "Reference" "SW" (at 0 {2.5:.4f} 0)\n'
        f'      (effects (font (size 1.27 1.27))))\n'
        f'    (property "Value" "SW_Push" (at 0 {-2.5:.4f} 0)\n'
        f'      (effects (font (size 1.27 1.27))))\n'
        f'    (symbol "SW_Push_0_1"\n'
        f'      (polyline (pts (xy {-L:.4f} 0) (xy {-0.5*L:.4f} 0))'
        f' (stroke (width 0) (type default)) (fill (type none)))\n'
        f'      (polyline (pts (xy {0.5*L:.4f} 0) (xy {L:.4f} 0))'
        f' (stroke (width 0) (type default)) (fill (type none)))\n'
        f'      (polyline (pts (xy {-0.5*L:.4f} {-0.5*L:.4f}) (xy {0.5*L:.4f} {-0.5*L:.4f}))'
        f' (stroke (width 0.1) (type default)) (fill (type none)))\n'
        f'      (arc (start {-0.5*L:.4f} 0) (mid 0 {0.4*L:.4f}) (end {0.5*L:.4f} 0)'
        f' (stroke (width 0.1) (type default)) (fill (type none))))\n'
        f'    (symbol "SW_Push_1_1"\n'
        f'      (pin passive line (at {-L:.4f} 0 0) (length 0)\n'
        f'        (name "A" (effects (font (size 1.016 1.016))))\n'
        f'        (number "1" (effects (font (size 1.016 1.016)))))\n'
        f'      (pin passive line (at {L:.4f} 0 180) (length 0)\n'
        f'        (name "B" (effects (font (size 1.016 1.016))))\n'
        f'        (number "2" (effects (font (size 1.016 1.016)))))\n'
        f'  ))'
    )
    return sym_text, by_num


# ── Load library symbols ───────────────────────────────────────────────────────
print("Loading KiCad library symbols...")

msp430_sym, msp430_n, msp430_p = extract_sym(
    'MCU_Texas_MSP430', 'MSP430G2553IN20')
hc165_sym, hc165_n, hc165_p  = extract_sym('74xx', '74HC165')
lm386_sym, lm386_n, lm386_p  = extract_sym('Amplifier_Audio', 'LM386')
flash_sym, flash_n, flash_p   = extract_sym('Memory_Flash', 'W25Q128JVS')
r_lib_sym, _, r_lib_p         = extract_sym('Device', 'R')
c_lib_sym, _, c_lib_p         = extract_sym('Device', 'C')

# ── Custom symbols ─────────────────────────────────────────────────────────────
sram_sym_txt,  sram_n,  sram_p  = make_sram_sym()
oled_sym_txt,  oled_n,  oled_p  = make_conn_sym(
    'Conn_OLED_7', ['GND', 'VCC', 'SCLK', 'MOSI', 'RST', 'DC', 'CS'])
lipo_sym_txt,  lipo_n,  lipo_p  = make_conn_sym(
    'Conn_LiPo_4', ['VCC', 'GND', 'BAT+', 'BAT-'])
r_sym_txt,     r_p      = make_passive_sym('R_custom', 'R', style='R')
c_sym_txt,     c_p      = make_passive_sym('C_custom', 'C', style='C')
spk_sym_txt,   spk_p    = make_speaker_sym()
sw_sym_txt,    sw_p     = make_sw_sym()
vcc_def = make_power_def('VCC', True)
gnd_def = make_power_def('GND', False)

# Use Device:R and Device:C from library; fall back to custom if unavailable
R_LIB  = 'Device:R'
C_LIB  = 'Device:C'
rp     = r_lib_p   # pin_by_num for resistor
cp     = c_lib_p   # pin_by_num for capacitor

# ── Pin lookups ────────────────────────────────────────────────────────────────
# MSP430G2553IN20 — keyed by pin number (names are too long)
# From MCU_Texas_MSP430 library (Y-up local convention):
msp = {
    # Left-side pins (lx=-43.18, connects on left → lbl rot=180)
    'RST':  (-43.18,  11.43),
    'P2.0': (-43.18,   7.62),
    'P2.1': (-43.18,   5.08),
    'P2.2': (-43.18,   2.54),
    'P2.3': (-43.18,   0.00),
    'P2.4': (-43.18,  -2.54),
    'P2.5': (-43.18,  -5.08),
    'P2.6': (-43.18,  -7.62),
    'P2.7': (-43.18, -10.16),
    # Right-side pins (lx=+43.18, connects on right → lbl rot=0)
    'TEST': (43.18,  13.97),
    'P1.0': (43.18,  10.16),
    'P1.1': (43.18,   7.62),
    'P1.2': (43.18,   5.08),
    'P1.3': (43.18,   2.54),
    'P1.4': (43.18,   0.00),
    'P1.5': (43.18,  -2.54),
    'P1.6': (43.18,  -5.08),
    'P1.7': (43.18,  -7.62),
    # Power
    'DVCC': ( 0.00,  20.32),
    'DVSS': ( 0.00, -19.05),
}

# 74HC165 (via 74LS165 parent) — use library pin_by_name
# Key names from KiCad 74LS165 symbol:
hc = hc165_n   # {pin_name: (lx, ly)}
# Convenience: manually verify expected keys exist
for k in ['~{PL}', 'CP', 'D0', 'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7',
          'DS', '~{CE}', 'Q7', '~{Q7}', 'VCC', 'GND']:
    if k not in hc:
        print(f"  WARN: 74HC165 missing pin name '{k}' — using num fallback")

# LM386 — library pin_by_name
lm = lm386_n   # {pin_name: (lx, ly)}

# W25Q128JVS — library pin_by_name (from W25Q32JVSS parent)
fl = flash_n   # {pin_name: (lx, ly)}

# SRAM 23LC1024 — custom pin_by_name
sr = sram_n

# ── Component positions ── (all integer multiples of G = 2.54 mm) ─────────────
#
#  Layout (schematic, Y-down: larger y = lower):
#
#       J1(OLED)  U4(SRAM)  U5(Flash)  J2(LiPo)
#                      U1(MSP430)
#  Btns  U2(SR)                          U3(LM386)  LS1(Speaker)
#
# MSP430 left-pin endpoints at x = U1x - 43.18 = U1x - 17G
# MSP430 right-pin endpoints at x = U1x + 43.18 = U1x + 17G

U1  = (80*G,  70*G)   # MSP430G2553 — center
U2  = (25*G,  58*G)   # SN74HC165N  — left of MSP430
U3  = (130*G, 70*G)   # LM386       — right of MSP430
U4  = (65*G,  20*G)   # 23LC1024 SRAM — above MCU
U5  = (90*G,  20*G)   # W25Q128 Flash — above MCU
J1  = (45*G,  20*G)   # OLED SPI connector — upper left
J2  = (112*G, 20*G)   # LiPo charger — upper right
LS1 = (150*G, 70*G)   # Speaker — far right

# Bypass caps (near their ICs)
C_MCU = (80*G,  36*G)  # 100nF bypass for MSP430 VCC
C_SR  = (25*G,  38*G)  # 100nF bypass for 74HC165
C_SRM = (65*G,  36*G)  # 100nF bypass for SRAM
C_FLS = (90*G,  36*G)  # 100nF bypass for Flash

# Audio RC filter: P1.2 → R_audio → C_audio → VOL_WIPER → LM386 pin 3
R_AUD = (112*G, 72*G)  # 1kΩ RC filter resistor
C_AUD = (112*G, 79*G)  # 10µF RC filter cap (coupling)
C_BYP = (130*G, 58*G)  # 10µF LM386 bypass (pin 7)
C_OUT = (143*G, 70*G)  # 220µF output coupling cap

# Buttons: 8 tactile switches on far left
BTN_X = 8*G
RPU_X = 16*G   # pull-up resistors
BTN_YS = [n*G for n in [42, 47, 52, 57, 62, 67, 72, 77]]
BTN_NETS = ['BTN_A', 'BTN_B', 'BTN_C', 'BTN_D',
            'BTN_E', 'BTN_F', 'BTN_G', 'BTN_H']


# ── Grid check ────────────────────────────────────────────────────────────────
def chk(name, val):
    r = val % G
    if r > 1e-9 and (G - r) > 1e-9:
        print(f"  WARN: {name}={val:.4f} not on G grid (rem={r:.6f})")

for label, pt in [('U1', U1), ('U2', U2), ('U3', U3), ('U4', U4), ('U5', U5),
                   ('J1', J1), ('J2', J2), ('LS1', LS1),
                   ('C_MCU', C_MCU), ('C_SR', C_SR), ('C_SRM', C_SRM),
                   ('C_FLS', C_FLS), ('R_AUD', R_AUD), ('C_AUD', C_AUD),
                   ('C_BYP', C_BYP), ('C_OUT', C_OUT)]:
    chk(f'{label}.x', pt[0])
    chk(f'{label}.y', pt[1])
chk('BTN_X', BTN_X)
chk('RPU_X', RPU_X)
for i, y in enumerate(BTN_YS):
    chk(f'BTN_Y[{i}]', y)
print("Grid check done.")


# ── Place ICs ─────────────────────────────────────────────────────────────────
place('MCU_Texas_MSP430:MSP430G2553IN20', *U1,  'U1', 'MSP430G2553')
place('74xx:74HC165',                     *U2,  'U2', 'SN74HC165N')
place('Amplifier_Audio:LM386',            *U3,  'U3', 'LM386N-1')
place('SRAM_23LC1024',                    *U4,  'U4', '23LC1024-I/P')
place('Memory_Flash:W25Q128JVS',          *U5,  'U5', 'W25Q128JVSSIQ')
place('Conn_OLED_7',                      *J1,  'J1', 'SSD1325_OLED')
place('Conn_LiPo_4',                      *J2,  'J2', 'LiPo_Charger')
place('Speaker',                          *LS1, 'LS1', 'SP-3605')

# Passives (using KiCad Device library)
place(C_LIB, *C_MCU, 'C1', '100nF')
place(C_LIB, *C_SR,  'C2', '100nF')
place(C_LIB, *C_SRM, 'C3', '100nF')
place(C_LIB, *C_FLS, 'C4', '100nF')
place(R_LIB, *R_AUD, 'R1', '1k')
place(C_LIB, *C_AUD, 'C5', '10uF')
place(C_LIB, *C_BYP, 'C6', '10uF')
place(C_LIB, *C_OUT, 'C7', '220uF')

# Buttons and pull-ups
for i, (by, bnet) in enumerate(zip(BTN_YS, BTN_NETS), 1):
    place('SW_Push', BTN_X, by, f'SW{i}', bnet)
    place(R_LIB,     RPU_X, by, f'R{i+1}', '10k')


# ── MSP430G2553 connections ───────────────────────────────────────────────────
def msp_w(pin):
    return pw(U1[0], U1[1], msp[pin][0], msp[pin][1])

pwr('VCC', *msp_w('DVCC'))
pwr('GND', *msp_w('DVSS'))
nc(*msp_w('P1.0'))                                          # LED1 (on LaunchPad)
nc(*msp_w('P1.1'))                                          # RXD (no UART in schematic)
lbl('PWM_OUT',  *msp_w('P1.2'), rot=0)                     # PWM audio
nc(*msp_w('P1.3'))                                          # on-board button S2
nc(*msp_w('P1.4'))
lbl('SCK',      *msp_w('P1.5'), rot=0)                     # SPI clock
lbl('MISO',     *msp_w('P1.6'), rot=0)                     # SPI MISO
lbl('MOSI',     *msp_w('P1.7'), rot=0)                     # SPI MOSI
lbl('OLED_CS',  *msp_w('P2.0'), rot=180)                   # OLED chip select
lbl('OLED_DC',  *msp_w('P2.1'), rot=180)                   # OLED data/cmd
lbl('OLED_RST', *msp_w('P2.2'), rot=180)                   # OLED reset
lbl('SRAM_CS',  *msp_w('P2.3'), rot=180)                   # SRAM chip select
lbl('FLASH_CS', *msp_w('P2.4'), rot=180)                   # Flash chip select
lbl('SH_LD',    *msp_w('P2.5'), rot=180)                   # SR parallel-load
nc(*msp_w('P2.6'))                                          # XIN
nc(*msp_w('P2.7'))                                          # XOUT
nc(*msp_w('RST'))
nc(*msp_w('TEST'))


# ── 74HC165 shift register connections ────────────────────────────────────────
def hc_w(pin_name):
    lx, ly = hc165_n.get(pin_name, hc165_p.get(pin_name, (None, None)))
    if lx is None:
        raise KeyError(f"74HC165 pin not found: '{pin_name}'")
    return pw(U2[0], U2[1], lx, ly)

lbl('SH_LD',  *hc_w('~{PL}'), rot=180)    # parallel load (active low) → SH_LD net
lbl('SCK',    *hc_w('CP'),    rot=180)    # clock
lbl('BTN_E',  *hc_w('D4'),   rot=180)
lbl('BTN_F',  *hc_w('D5'),   rot=180)
lbl('BTN_G',  *hc_w('D6'),   rot=180)
lbl('BTN_H',  *hc_w('D7'),   rot=180)
pwr('GND',    *hc_w('~{CE}'))              # clock inhibit → GND
lbl('BTN_D',  *hc_w('D3'),   rot=180)
lbl('BTN_C',  *hc_w('D2'),   rot=180)
lbl('BTN_B',  *hc_w('D1'),   rot=180)
lbl('BTN_A',  *hc_w('D0'),   rot=180)
pwr('GND',    *hc_w('DS'))                 # serial cascade in → GND
nc(           *hc_w('~{Q7}'))             # inverted output, not used
lbl('MISO',   *hc_w('Q7'),   rot=0)       # serial out → MISO
pwr('VCC',    *hc_w('VCC'))
pwr('GND',    *hc_w('GND'))


# ── LM386 connections ─────────────────────────────────────────────────────────
def lm_w(pin_name):
    lx, ly = lm386_n[pin_name]
    return pw(U3[0], U3[1], lx, ly)

lbl('VOL_WIPER', *lm_w('+'),      rot=180)   # non-inverting input from vol pot
pwr('GND',       *lm_w('-'))                  # inverting input → GND
pwr('VCC',       *lm_w('V+'))
pwr('GND',       *lm_w('GND'))
lbl('LM386_BYP', *lm_w('BYPASS'), rot=0)     # pin 7 → bypass cap
nc(*lm_w('GAIN'))                              # pin 1 GAIN (leave open = 20× gain)
# Pin 8 (GAIN) — same name as pin 1 in library; look up by number
lx8, ly8 = lm386_p['8']
nc(*pw(U3[0], U3[1], lx8, ly8))              # pin 8 GAIN
lbl('SPK_OUT',   *lm_w('~'),      rot=0)     # output (pin 5, named '~' in lib)


# ── W25Q128JVS Flash connections ──────────────────────────────────────────────
def fl_w(pin_name):
    lx, ly = flash_n[pin_name]
    return pw(U5[0], U5[1], lx, ly)

lbl('FLASH_CS',  *fl_w('~{CS}'),              rot=180)
lbl('MISO',      *fl_w('DO/IO_{1}'),          rot=180)
pwr('VCC',       *fl_w('~{WP}/IO_{2}'))       # WP# → VCC (write protect disabled)
pwr('GND',       *fl_w('GND'))
lbl('MOSI',      *fl_w('DI/IO_{0}'),          rot=180)
lbl('SCK',       *fl_w('CLK'),                rot=180)
pwr('VCC',       *fl_w('~{HOLD}/~{RESET}/IO_{3}'))   # HOLD# → VCC
pwr('VCC',       *fl_w('VCC'))


# ── 23LC1024 SRAM connections ─────────────────────────────────────────────────
def sr_w(pin_name):
    lx, ly = sram_n[pin_name]
    return pw(U4[0], U4[1], lx, ly)

lbl('SRAM_CS', *sr_w('CS'),   rot=180)
lbl('MISO',    *sr_w('SO'),   rot=180)
nc(            *sr_w('NC'))
lbl('MOSI',    *sr_w('SI'),   rot=180)
lbl('SCK',     *sr_w('SCK'),  rot=180)
pwr('VCC',     *sr_w('HOLD'))              # HOLD# → VCC
pwr('VCC',     *sr_w('VCC'))
pwr('GND',     *sr_w('GND'))


# ── OLED connector J1 ─────────────────────────────────────────────────────────
def j1_w(pin_name):
    lx, ly = oled_n[pin_name]
    return pw(J1[0], J1[1], lx, ly)

pwr('GND',      *j1_w('GND'))
pwr('VCC',      *j1_w('VCC'))
lbl('SCK',      *j1_w('SCLK'), rot=180)
lbl('MOSI',     *j1_w('MOSI'), rot=180)
lbl('OLED_RST', *j1_w('RST'),  rot=180)
lbl('OLED_DC',  *j1_w('DC'),   rot=180)
lbl('OLED_CS',  *j1_w('CS'),   rot=180)


# ── LiPo charger J2 ──────────────────────────────────────────────────────────
def j2_w(pin_name):
    lx, ly = lipo_n[pin_name]
    return pw(J2[0], J2[1], lx, ly)

pwr('VCC',   *j2_w('VCC'))
pwr('GND',   *j2_w('GND'))
lbl('BAT_P', *j2_w('BAT+'), rot=180)
lbl('BAT_N', *j2_w('BAT-'), rot=180)


# ── Speaker LS1 ───────────────────────────────────────────────────────────────
lbl('SPK_OUT', *pw(LS1[0], LS1[1], spk_p['1'][0], spk_p['1'][1]), rot=180)
pwr('GND',     *pw(LS1[0], LS1[1], spk_p['2'][0], spk_p['2'][1]))


# ── Audio RC filter chain ─────────────────────────────────────────────────────
# R_AUD: PWM_OUT → R1 → C_AUD top → vol pot wiper → LM386 pin 3
lbl('PWM_OUT',   *pw(R_AUD[0], R_AUD[1], rp['1'][0], rp['1'][1]), rot=270)
lbl('FILT_MID',  *pw(R_AUD[0], R_AUD[1], rp['2'][0], rp['2'][1]), rot=90)
lbl('FILT_MID',  *pw(C_AUD[0], C_AUD[1], cp['1'][0], cp['1'][1]), rot=270)
lbl('VOL_WIPER', *pw(C_AUD[0], C_AUD[1], cp['2'][0], cp['2'][1]), rot=90)


# ── Bypass capacitors ─────────────────────────────────────────────────────────
for cap_pos in [C_MCU, C_SR, C_SRM, C_FLS]:
    pwr('VCC', *pw(cap_pos[0], cap_pos[1], cp['1'][0], cp['1'][1]))
    pwr('GND', *pw(cap_pos[0], cap_pos[1], cp['2'][0], cp['2'][1]))

# LM386 bypass cap (pin 7)
pwr('VCC', *pw(C_BYP[0], C_BYP[1], cp['1'][0], cp['1'][1]))
lbl('LM386_BYP', *pw(C_BYP[0], C_BYP[1], cp['2'][0], cp['2'][1]), rot=90)

# Output coupling cap
lbl('SPK_OUT',  *pw(C_OUT[0], C_OUT[1], cp['1'][0], cp['1'][1]), rot=270)
lbl('SPK_RAW',  *pw(C_OUT[0], C_OUT[1], cp['2'][0], cp['2'][1]), rot=90)


# ── 8 tactile buttons + pull-up resistors ─────────────────────────────────────
for i, (by, bnet) in enumerate(zip(BTN_YS, BTN_NETS), 1):
    # Button: pin 1 → GND,  pin 2 → BTN net
    pwr('GND', *pw(BTN_X, by, sw_p['1'][0], sw_p['1'][1]))
    lbl(bnet,  *pw(BTN_X, by, sw_p['2'][0], sw_p['2'][1]), rot=0)
    # Pull-up: pin 1 → VCC,  pin 2 → BTN net
    pwr('VCC', *pw(RPU_X, by, rp['1'][0], rp['1'][1]))
    lbl(bnet,  *pw(RPU_X, by, rp['2'][0], rp['2'][1]), rot=90)


# ── Assemble lib_symbols block ────────────────────────────────────────────────
lib_block = '\n'.join([
    msp430_sym,
    hc165_sym,
    lm386_sym,
    flash_sym,
    r_lib_sym,
    c_lib_sym,
    sram_sym_txt,
    oled_sym_txt,
    lipo_sym_txt,
    spk_sym_txt,
    sw_sym_txt,
    vcc_def,
    gnd_def,
])

all_elements = '\n'.join(
    f'  {e}' for e in (PLACED + WIRES + LABELS + POWERS + NC)
)

# ── Build schematic ────────────────────────────────────────────────────────────
sch = f"""(kicad_sch
  (version 20250114)
  (generator "eeschema")
  (generator_version "9.0")
  (uuid "{uid()}")
  (paper "B")
  (title_block
    (title "MSP430G2553 Handheld Game Console")
    (date "2026-03-21")
    (rev "5.0")
    (company "")
    (comment 1 "MCU: MSP430G2553 (LaunchPad MSP-EXP430G2ET)")
    (comment 2 "SPI bus (USCI_B0): P1.5=SCK  P1.6=MISO  P1.7=MOSI")
    (comment 3 "CS: P2.0=OLED_CS  P2.1=OLED_DC  P2.2=OLED_RST  P2.3=SRAM_CS  P2.4=FLASH_CS  P2.5=SH/LD#")
    (comment 4 "Buttons: 74HC165 parallel-in/serial-out, 10k pull-ups to VCC, BTN_A..H")
  )
  (lib_symbols
{lib_block}
  )
{all_elements}
  (sheet_instances
    (path "/" (page "1"))
  )
)
"""

# ── Validate ──────────────────────────────────────────────────────────────────
opens  = sch.count('(')
closes = sch.count(')')
assert opens == closes, f"PAREN MISMATCH: {opens} open vs {closes} close"

OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
OUT_PATH.write_text(sch)

print(f"Written: {OUT_PATH}")
print(f"  Size:   {OUT_PATH.stat().st_size:,} bytes")
print(f"  Lines:  {sch.count(chr(10))}")
print(f"  Parens: {opens} open = {closes} close ✓")
print(f"  Placed: {len(PLACED)}  Wires: {len(WIRES)}"
      f"  Labels: {len(LABELS)}  Powers: {len(POWERS)}  NC: {len(NC)}")

# KiCad 9 format audit
checks = [
    ('version 20250114',   '(version 20250114)' in sch),
    ('generator_version',  '"9.0"' in sch),
    ('exclude_from_sim',   'exclude_from_sim' in sch),
    ('dnp field',          '(dnp no)' in sch),
    ('fields_autoplaced',  'fields_autoplaced' in sch),
    ('justify left',       'justify left' in sch),
]
for name, ok in checks:
    print(f"  {'✓' if ok else '✗'} {name}")
