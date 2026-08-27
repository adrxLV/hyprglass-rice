#!/usr/bin/env python3
import sys
import math
import re
import json

SUB_MAP = {"0":"₀", "1":"₁", "2":"₂", "3":"₃", "4":"₄", "5":"₅", "6":"₆", "7":"₇", "8":"₈", "9":"₉"}

def to_subscript(num):
    return "".join(SUB_MAP.get(c, c) for c in str(num))

def format_num(val):
    if isinstance(val, complex):
        r = round(val.real, 4)
        i = round(val.imag, 4)
        if abs(i) < 1e-6:
            val = r
        elif abs(r) < 1e-6:
            return f"{i}i"
        else:
            sign = "+" if i >= 0 else "-"
            return f"{r} {sign} {abs(i)}i"
    
    if isinstance(val, (int, float)):
        if abs(val - round(val)) < 1e-6:
            return str(int(round(val)))
        return f"{val:.4f}".rstrip('0').rstrip('.')
    return str(val)

def clean_expr(s):
    s = s.replace(" ", "").replace("^", "**")
    s = s.replace("sen", "sin")
    s = re.sub(r"(\d)([a-zA-Z\(])", r"\1*\2", s)
    s = re.sub(r"(\))([a-zA-Z0-9\(])", r"\1*\2", s)
    return s

def eval_f(expr_str, x_val):
    safe_dict = {
        "x": x_val, "math": math, "sin": math.sin, "cos": math.cos,
        "tan": math.tan, "asin": math.asin, "acos": math.acos, "atan": math.atan,
        "sqrt": math.sqrt, "log": math.log, "log10": math.log10, "exp": math.exp,
        "abs": abs, "pi": math.pi, "e": math.e
    }
    return float(eval(clean_expr(expr_str), {"__builtins__": None}, safe_dict))

def solve_linear(a, b):
    if abs(a) < 1e-9:
        return []
    return [-b / a]

def solve_quadratic(a, b, c):
    delta = b**2 - 4*a*c
    if abs(delta) < 1e-9:
        return [-b / (2*a)]
    elif delta > 0:
        x1 = (-b + math.sqrt(delta)) / (2*a)
        x2 = (-b - math.sqrt(delta)) / (2*a)
        return sorted([x1, x2])
    else:
        real = -b / (2*a)
        imag = math.sqrt(-delta) / (2*a)
        return [complex(real, imag), complex(real, -imag)]

def solve_cubic(a, b, c, d):
    p = (3*a*c - b**2) / (3*a**2)
    q = (2*b**3 - 9*a*b*c + 27*a**2*d) / (27*a**3)
    delta = (q/2)**2 + (p/3)**3
    shift = -b / (3*a)

    if abs(delta) < 1e-9:
        delta = 0

    if delta > 0:
        u_val = -q/2 + math.sqrt(delta)
        u = (u_val)**(1/3) if u_val >= 0 else -(-u_val)**(1/3)
        v_val = -q/2 - math.sqrt(delta)
        v = (v_val)**(1/3) if v_val >= 0 else -(-v_val)**(1/3)
        t1 = u + v
        real_part = -(u + v)/2
        imag_part = (u - v) * math.sqrt(3)/2
        r1 = t1 + shift
        r2 = complex(real_part + shift, abs(imag_part))
        r3 = complex(real_part + shift, -abs(imag_part))
        return [r1, r2, r3]
    elif delta == 0:
        if p == 0:
            return [shift]
        u_val = -q/2
        u = (u_val)**(1/3) if u_val >= 0 else -(-u_val)**(1/3)
        return [2*u + shift, -u + shift]
    else:
        r = math.sqrt(-(p/3)**3)
        phi = math.acos(max(-1.0, min(1.0, -q / (2*r))))
        t1 = 2 * (r**(1/3)) * math.cos(phi/3)
        t2 = 2 * (r**(1/3)) * math.cos((phi + 2*math.pi)/3)
        t3 = 2 * (r**(1/3)) * math.cos((phi + 4*math.pi)/3)
        return sorted([t1 + shift, t2 + shift, t3 + shift])

def extract_poly(expr_str):
    try:
        y0 = eval_f(expr_str, 0)
        y1 = eval_f(expr_str, 1)
        y2 = eval_f(expr_str, 2)
        y3 = eval_f(expr_str, 3)
        y4 = eval_f(expr_str, 4)

        if abs(y0 - y1) < 1e-7 and abs(y1 - y2) < 1e-7 and abs(y2 - y3) < 1e-7:
            return [y0]

        b = y0
        a = y1 - y0
        if abs(eval_f(expr_str, 2) - (2*a + b)) < 1e-5 and abs(eval_f(expr_str, 3) - (3*a + b)) < 1e-5:
            return [a, b]

        c = y0
        a2 = y2/2.0 - y1 + c/2.0
        b2 = y1 - c - a2
        if abs(eval_f(expr_str, 3) - (9*a2 + 3*b2 + c)) < 1e-4 and abs(eval_f(expr_str, 4) - (16*a2 + 4*b2 + c)) < 1e-4:
            return [a2, b2, c]

        d = y0
        u1 = y1 - d
        u2 = (y2 - d) / 2.0
        u3 = (y3 - d) / 3.0
        a3 = (u3 - 2.0*u2 + u1) / 2.0
        b3 = (u2 - u1) - 3.0*a3
        c3 = u1 - a3 - b3
        if abs(eval_f(expr_str, 4) - (64*a3 + 16*b3 + 4*c3 + d)) < 1e-3:
            return [a3, b3, c3, d]
    except Exception:
        pass
    return None

def process_query(raw_input):
    raw_input = raw_input.strip()
    if not raw_input:
        return {"status": "empty"}

    expr = raw_input
    is_explicit_func = (
        raw_input.startswith("f(x)") or raw_input.startswith("g(x)") or
        raw_input.startswith("y =") or raw_input.startswith("y=") or
        "f(x)" in raw_input or "g(x)" in raw_input
    )
    
    if "=" in expr and not is_explicit_func:
        parts = expr.split("=")
        left, right = parts[0].strip(), parts[1].strip()
        expr = f"({left}) - ({right})"
    elif is_explicit_func and "=" in expr:
        parts = expr.split("=")
        expr = parts[1].strip()

    has_x = "x" in expr.lower()

    if not has_x and not is_explicit_func:
        # Pure arithmetic
        try:
            safe_dict = {
                "math": math, "sin": math.sin, "cos": math.cos, "tan": math.tan,
                "asin": math.asin, "acos": math.acos, "atan": math.atan,
                "sqrt": math.sqrt, "log": math.log, "log10": math.log10, "exp": math.exp,
                "abs": abs, "pi": math.pi, "e": math.e
            }
            res = eval(clean_expr(expr), {"__builtins__": None}, safe_dict)
            return {
                "status": "success",
                "expr_type": "arithmetic",
                "has_graph": False,
                "display_title": raw_input,
                "main_result": f"{format_num(res)}",
                "roots": [],
                "details": "",
                "graph": None
            }
        except Exception:
            return {"status": "error", "has_graph": False, "main_result": ""}

    # Evaluate polynomial / general function of x
    poly = extract_poly(expr)
    roots = []
    details = ""

    if poly:
        degree = len(poly) - 1
        if degree == 1:
            r = solve_linear(poly[0], poly[1])
            roots = r
        elif degree == 2:
            a, b, c = poly[0], poly[1], poly[2]
            r = solve_quadratic(a, b, c)
            roots = r
        elif degree == 3:
            r = solve_cubic(poly[0], poly[1], poly[2], poly[3])
            roots = r
    else:
        found_roots = []
        try:
            prev_x = -15.0
            prev_y = eval_f(expr, prev_x)
            step = 0.2
            x_curr = -15.0 + step
            while x_curr <= 15.0:
                try:
                    curr_y = eval_f(expr, x_curr)
                    if abs(curr_y) < 1e-4:
                        found_roots.append(round(x_curr, 4))
                    elif prev_y * curr_y < 0:
                        low, high = x_curr - step, x_curr
                        for _ in range(20):
                            mid = (low + high) / 2.0
                            m_y = eval_f(expr, mid)
                            if eval_f(expr, low) * m_y <= 0:
                                high = mid
                            else:
                                low = mid
                        found_roots.append(round((low + high) / 2.0, 4))
                except Exception:
                    pass
                prev_x, prev_y = x_curr, curr_y
                x_curr += step
            roots = found_roots
        except Exception:
            pass

    # Main result & roots list formatting
    if len(roots) == 1:
        main_res = f"x = {format_num(roots[0])}"
        roots_formatted = []
    elif len(roots) >= 2:
        roots_formatted = [f"x{to_subscript(i+1)} = {format_num(r)}" for i, r in enumerate(roots)]
        main_res = ",  ".join(roots_formatted)
    else:
        main_res = f"f(0) = {format_num(eval_f(expr, 0)) if poly else '0'}"
        roots_formatted = []

    # Graph generation ONLY if explicit function (e.g. f(x) = ...)
    graph_obj = None
    if is_explicit_func:
        pts = []
        zeros_pts = []
        y_vals = []
        x_step = 0.2
        cur_x = -10.0
        while cur_x <= 10.001:
            try:
                val_y = eval_f(expr, cur_x)
                if not math.isnan(val_y) and not math.isinf(val_y) and abs(val_y) < 1000:
                    pts.append([round(cur_x, 2), round(val_y, 4)])
                    y_vals.append(val_y)
            except Exception:
                pass
            cur_x += x_step

        for r in roots:
            if isinstance(r, (int, float)):
                if -10 <= r <= 10:
                    zeros_pts.append([round(r, 4), 0.0])

        y_min = min(y_vals) if y_vals else -10.0
        y_max = max(y_vals) if y_vals else 10.0
        y_margin = max(1.0, (y_max - y_min) * 0.1)
        graph_obj = {
            "xMin": -10.0,
            "xMax": 10.0,
            "yMin": round(y_min - y_margin, 2),
            "yMax": round(y_max + y_margin, 2),
            "points": pts,
            "zeros": zeros_pts
        }

    return {
        "status": "success",
        "expr_type": "function" if is_explicit_func else "equation",
        "has_graph": is_explicit_func,
        "input_raw": raw_input,
        "display_title": raw_input,
        "main_result": main_res,
        "roots": roots_formatted,
        "details": "",
        "graph": graph_obj
    }

if __name__ == "__main__":
    if len(sys.argv) > 1:
        query = " ".join(sys.argv[1:])
    else:
        query = sys.stdin.read()
    res = process_query(query)
    print(json.dumps(res, ensure_ascii=False))
