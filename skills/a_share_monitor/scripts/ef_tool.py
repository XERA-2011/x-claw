#!/usr/bin/env python3
import argparse
import json
import sys
from typing import Any, Dict


def _require_efinance():
    try:
        import efinance as ef  # type: ignore
    except Exception as exc:  # pragma: no cover
        print("efinance is not installed. Run: pip install efinance", file=sys.stderr)
        raise SystemExit(1) from exc
    return ef


def _pick_first(df):
    if df is None or df.empty:
        return None
    return df.iloc[0]


def _get_field(row, keys):
    for key in keys:
        if key in row:
            return row[key]
    return None


def _format_quote(row: Dict[str, Any]) -> str:
    code = _get_field(row, ["股票代码", "代码", "证券代码", "code"]) or ""
    name = _get_field(row, ["股票名称", "名称", "证券名称", "name"]) or ""
    price = _get_field(row, ["最新价", "现价", "price", "最新"])
    pct = _get_field(row, ["涨跌幅", "涨跌幅(%)", "pct_chg", "涨跌%"])
    turnover = _get_field(row, ["成交额", "成交额(元)", "turnover", "amount"])

    return (
        f"代码: {code}\n"
        f"名称: {name}\n"
        f"最新价: {price}\n"
        f"涨跌幅: {pct}\n"
        f"成交额: {turnover}"
    )


def _fetch_quote(ef, query: str):
    df = ef.stock.get_latest_quote(query)
    row = _pick_first(df)
    if row is None:
        return None
    return row.to_dict()


def _fetch_lhb(ef, code: str):
    # Best-effort: efinance LHB API names vary by version
    candidates = [
        ("get_lhb_detail", {"stock_code": code}),
        ("get_lhb_stock", {"stock_code": code}),
        ("get_lhb_list", {"stock_code": code}),
    ]
    for fn_name, kwargs in candidates:
        fn = getattr(ef.stock, fn_name, None)
        if fn is None:
            continue
        try:
            df = fn(**kwargs)
            if df is not None and not df.empty:
                return df
        except Exception:
            continue
    return None


def main():
    parser = argparse.ArgumentParser(description="A-share monitor via efinance")
    parser.add_argument("--query", required=True, help="Stock name or 6-digit code")
    parser.add_argument("--lhb", action="store_true", help="Include LHB data if available")
    parser.add_argument("--market", action="store_true", help="Return A-share market index snapshot")
    parser.add_argument("--json", action="store_true", help="Return JSON output")
    args = parser.parse_args()

    ef = _require_efinance()

    if args.market:
        indices = ["上证指数", "深证成指", "创业板指", "沪深300"]
        rows = []
        for name in indices:
            df = ef.stock.get_latest_quote(name)
            row = _pick_first(df)
            if row is not None:
                rows.append(row.to_dict())
        if not rows:
            print("No market data returned.", file=sys.stderr)
            raise SystemExit(3)
        if args.json:
            print(json.dumps({"market": rows}, ensure_ascii=False, indent=2))
            return
        print("A股指数快照:")
        for row in rows:
            print(_format_quote(row))
            print("---")
        return

    quote = _fetch_quote(ef, args.query)
    if quote is None:
        print("No quote data returned.", file=sys.stderr)
        raise SystemExit(3)

    result: Dict[str, Any] = {"quote": quote}
    if args.lhb:
        code = _get_field(quote, ["代码", "股票代码", "证券代码", "code"])
        if not code:
            print("Could not resolve stock code for LHB.", file=sys.stderr)
            raise SystemExit(2)
        lhb = _fetch_lhb(ef, str(code))
        if lhb is not None:
            result["lhb"] = lhb.to_dict(orient="records")

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return

    print(_format_quote(quote))
    if args.lhb and "lhb" in result:
        print("\nLHB:")
        print(json.dumps(result["lhb"], ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
