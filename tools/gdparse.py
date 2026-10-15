import re, glob, sys

def strip_comments(line, in_str):
    out = []
    i = 0
    qc = ''
    while i < len(line):
        ch = line[i]
        if in_str:
            if ch == '\\':
                i += 2
                continue
            if ch == qc:
                in_str = False
            i += 1
            continue
        if ch in '"\'':
            # triple quote handling
            if line[i:i+3] in ('"""', "'''"):
                return ''.join(out), None  # signal multiline; caller handles
            in_str = True
            qc = ch
        elif ch == '#':
            break
        out.append(ch)
        i += 1
    return ''.join(out), in_str

def logical_lines(path):
    """Yield (start_line_no, text) of logical lines joining continuations inside brackets."""
    raw = open(path).read().split('\n')
    lls = []
    i = 0
    in_str_state = False
    while i < len(raw):
        code, st = strip_comments(raw[i], in_str_state)
        start = i + 1
        buf = code
        depth_open = None
        # track bracket balance across joined physical lines
        def bal(s):
            d = {'(': 0, '[': 0, '{': 0}
            ins = False; qc = ''
            j = 0
            while j < len(s):
                c = s[j]
                if ins:
                    if c == '\\': j += 2; continue
                    if c == qc: ins = False
                else:
                    if c in '"\'': ins = True; qc = c
                    elif c in d: d[c] += 1
                    elif c == ')': d['('] -= 1
                    elif c == ']': d['['] -= 1
                    elif c == '}': d['{'] -= 1
                j += 1
            return sum(d.values()), ins
        total, unclosed_str = bal(buf)
        while (total > 0 or unclosed_str) and i + 1 < len(raw):
            i += 1
            nxt, st2 = strip_comments(raw[i], unclosed_str)
            buf += '\n' + nxt
            total, unclosed_str = bal(buf)
        lls.append((start, buf, raw[start-1]))
        i += 1
    return lls

errs_all = 0
for path in sorted(glob.glob('/workspace/scripts/**/*.gd', recursive=True)):
    errs = []
    stack = [(-1,)]  # indent level (tabs) of enclosing block header lines
    for start, full, firstline in logical_lines(path):
        s = full.strip()
        if not s:
            continue
        indent = len(firstline) - len(firstline.lstrip('\t'))
        lead = firstline[:indent]
        if ' ' in lead:
            errs.append((start, 'space in indent'))
        if len(firstline) > indent and firstline[indent] == ' ':
            errs.append((start, 'space-indented line'))
        # pop stack to current level
        while len(stack) > 1 and indent < stack[-1][0]:
            stack.pop()
        if len(stack) > 1 and indent > stack[-1][0] + 1:
            errs.append((start, 'indent jump %d vs parent %d' % (indent, stack[-1][0])))
        # block opener? ends with ':' at depth 0 outside strings
        def ends_colon(t):
            ins = False; qc = ''; d = 0
            j = 0
            while j < len(t):
                c = t[j]
                if ins:
                    if c == '\\': j += 2; continue
                    if c == qc: ins = False
                else:
                    if c in '"\'': ins = True; qc = c
                    elif c in '([{': d += 1
                    elif c in ')]}': d -= 1
                j += 1
            return t.rstrip().endswith(':') and d == 0 and not ins
        if ends_colon(full):
            stack.append((indent,))
        # inline statements after ':' e.g. 'if x: return false' -> fine in GDScript
    if errs:
        errs_all += 1
        print('== ' + path)
        for n, m in errs:
            print('   line %d: %s' % (n, m))
print('FILES WITH ISSUES:', errs_all)
