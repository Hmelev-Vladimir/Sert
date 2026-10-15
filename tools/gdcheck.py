import re, glob

def strip_code(line):
    out = []
    i = 0
    instr = False
    q = ''
    while i < len(line):
        ch = line[i]
        if instr:
            if ch == '\\':
                i += 2
                continue
            if ch == q:
                instr = False
            i += 1
            continue
        if ch in '"\'':
            instr = True
            q = ch
        elif ch == '#':
            break
        out.append(ch)
        i += 1
    return ''.join(out)

def check(path):
    errs = []
    lines = open(path).read().split('\n')
    for n, raw in enumerate(lines, 1):
        code = strip_code(raw)
        s = code.strip()
        if not s:
            continue
        lead = code[:len(code) - len(code.lstrip())]
        if ' ' in lead:
            errs.append((n, 'space in indent'))
        bal = {'(': 0, '[': 0, '{': 0}
        ins = False
        qc = ''
        i = 0
        while i < len(code):
            ch = code[i]
            if ins:
                if ch == '\\':
                    i += 2
                    continue
                if ch == qc:
                    ins = False
            else:
                if ch in '"\'':
                    ins = True
                    qc = ch
                elif ch in bal:
                    bal[ch] += 1
                elif ch == ')':
                    bal['('] -= 1
                elif ch == ']':
                    bal['['] -= 1
                elif ch == '}':
                    bal['{'] -= 1
            i += 1
        if any(v != 0 for v in bal.values()):
            errs.append((n, 'unbalanced brackets: %s' % s[:60]))
        if ins:
            errs.append((n, 'unterminated string: %s' % s[:60]))
    return errs

bad = 0
for p in sorted(glob.glob('/workspace/scripts/**/*.gd', recursive=True)):
    e = check(p)
    if e:
        bad += 1
        print('== ' + p)
        for n, m in e:
            print('   line %d: %s' % (n, m))
print('FILES WITH ISSUES:', bad)
