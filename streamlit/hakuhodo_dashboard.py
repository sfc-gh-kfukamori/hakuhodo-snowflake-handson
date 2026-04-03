import streamlit as st
from snowflake.snowpark.context import get_active_session

session = get_active_session()

st.title("博報堂 データダッシュボード")
st.caption("Snowflake ハンズオン — Streamlit in Snowflake + Cortex AI")

# --------------------------------------------------
# タブ構成
# --------------------------------------------------
tab1, tab2, tab3 = st.tabs(["仕入分析", "組織損益分析", "AI 問い合わせ"])

# ==========================================================
# Tab 1: 仕入分析
# ==========================================================
with tab1:
    st.header("仕入データ分析")

    # フィルタ用の選択肢を取得
    ym_rows = session.sql(
        'SELECT DISTINCT "年月" FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY ORDER BY "年月" DESC'
    ).collect()
    ym_options = [int(r["年月"]) for r in ym_rows]

    agency_rows = session.sql(
        'SELECT DISTINCT AGENCY_KEY FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY WHERE AGENCY_KEY IS NOT NULL ORDER BY AGENCY_KEY'
    ).collect()
    agency_options = [r["AGENCY_KEY"] for r in agency_rows]

    media_rows = session.sql(
        'SELECT DISTINCT "マスメディア区分名" FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY WHERE "マスメディア区分名" IS NOT NULL ORDER BY "マスメディア区分名"'
    ).collect()
    media_options = [r["マスメディア区分名"] for r in media_rows]

    # フィルタUI
    col_f1, col_f2, col_f3 = st.columns(3)
    with col_f1:
        selected_ym = st.multiselect("年月", options=ym_options, default=ym_options[:3])
    with col_f2:
        selected_agency = st.multiselect("代理店系列", options=agency_options, default=agency_options)
    with col_f3:
        selected_media = st.multiselect("マスメディア区分", options=media_options, default=media_options)

    # フィルタ条件構築
    q = "'"
    ym_clause = ",".join([str(y) for y in selected_ym]) if selected_ym else "0"
    agency_clause = ",".join([f"{q}{a}{q}" for a in selected_agency]) if selected_agency else f"{q}{q}"
    media_clause = ",".join([f"{q}{m}{q}" for m in selected_media]) if selected_media else f"{q}{q}"

    # KPI
    kpi_rows = session.sql(f"""
        SELECT
            COALESCE(SUM("仕入高合計"), 0) AS TOTAL_PURCHASE,
            COALESCE(SUM("媒体収益合計"), 0) AS TOTAL_REVENUE,
            COALESCE(SUM("媒体収益予算合計"), 0) AS TOTAL_BUDGET,
            COALESCE(SUM("取引件数"), 0) AS TOTAL_DEALS
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
        WHERE "年月" IN ({ym_clause})
          AND (AGENCY_KEY IN ({agency_clause}) OR AGENCY_KEY IS NULL)
          AND ("マスメディア区分名" IN ({media_clause}) OR "マスメディア区分名" IS NULL)
    """).collect()

    kpi = kpi_rows[0]
    k1, k2, k3, k4 = st.columns(4)
    k1.metric("仕入高合計", f"¥{int(kpi['TOTAL_PURCHASE']):,}")
    k2.metric("媒体収益合計", f"¥{int(kpi['TOTAL_REVENUE']):,}")
    budget_val = int(kpi["TOTAL_BUDGET"])
    revenue_val = int(kpi["TOTAL_REVENUE"])
    rate = round(revenue_val / budget_val * 100, 1) if budget_val else 0
    k3.metric("予実達成率", f"{rate}%")
    k4.metric("取引件数", f"{int(kpi['TOTAL_DEALS']):,}")

    st.divider()

    # チャート
    col_c1, col_c2 = st.columns(2)
    with col_c1:
        st.subheader("月別 仕入高推移")
        monthly_df = session.sql(f"""
            SELECT "年月"::VARCHAR AS "年月",
                   SUM("仕入高合計") AS "仕入高",
                   SUM("媒体収益合計") AS "媒体収益"
            FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
            WHERE "年月" IN ({ym_clause})
              AND (AGENCY_KEY IN ({agency_clause}) OR AGENCY_KEY IS NULL)
            GROUP BY "年月"
            ORDER BY "年月"
        """)
        st.bar_chart(monthly_df, x="年月", y=["仕入高", "媒体収益"])

    with col_c2:
        st.subheader("媒体種類別 仕入高構成")
        media_type_df = session.sql(f"""
            SELECT "媒体種類名",
                   SUM("仕入高合計") AS "仕入高"
            FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
            WHERE "年月" IN ({ym_clause})
              AND (AGENCY_KEY IN ({agency_clause}) OR AGENCY_KEY IS NULL)
              AND "媒体種類名" IS NOT NULL
            GROUP BY "媒体種類名"
            ORDER BY "仕入高" DESC
            LIMIT 10
        """)
        st.bar_chart(media_type_df, x="媒体種類名", y="仕入高")

    # 詳細テーブル
    st.subheader("詳細データ")
    detail_df = session.sql(f"""
        SELECT *
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
        WHERE "年月" IN ({ym_clause})
          AND (AGENCY_KEY IN ({agency_clause}) OR AGENCY_KEY IS NULL)
          AND ("マスメディア区分名" IN ({media_clause}) OR "マスメディア区分名" IS NULL)
        ORDER BY "年月" DESC, "仕入高合計" DESC
        LIMIT 100
    """)
    st.dataframe(detail_df, use_container_width=True)

# ==========================================================
# Tab 2: 組織損益分析
# ==========================================================
with tab2:
    st.header("組織損益分析（予算 vs 実績）")

    # フィルタ
    company_rows = session.sql(
        'SELECT DISTINCT "会社" FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY WHERE "会社" IS NOT NULL ORDER BY "会社"'
    ).collect()
    company_options = [r["会社"] for r in company_rows]

    dept_rows = session.sql(
        'SELECT DISTINCT "部門G" FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY WHERE "部門G" IS NOT NULL ORDER BY "部門G"'
    ).collect()
    dept_options = [r["部門G"] for r in dept_rows]

    col_o1, col_o2 = st.columns(2)
    with col_o1:
        selected_company = st.multiselect("会社", options=company_options, default=company_options)
    with col_o2:
        selected_dept = st.multiselect("部門グループ", options=dept_options, default=dept_options)

    q2 = "'"
    company_clause = ",".join([f"{q2}{c}{q2}" for c in selected_company]) if selected_company else f"{q2}{q2}"
    dept_clause = ",".join([f"{q2}{d}{q2}" for d in selected_dept]) if selected_dept else f"{q2}{q2}"

    # 予実比較チャート
    st.subheader("管理項目別 予算 vs 実績")
    pv_df = session.sql(f"""
        SELECT
            "管理項目名称",
            SUM("実績合計") AS "実績",
            SUM("予算合計") AS "予算"
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
        WHERE ("会社" IN ({company_clause}) OR "会社" IS NULL)
          AND ("部門G" IN ({dept_clause}) OR "部門G" IS NULL)
        GROUP BY "管理項目名称"
        HAVING SUM("予算合計") <> 0
        ORDER BY "実績" DESC
        LIMIT 15
    """)
    st.bar_chart(pv_df, x="管理項目名称", y=["実績", "予算"])

    # 月次推移
    st.subheader("月次 予実推移")
    monthly_pv_df = session.sql(f"""
        SELECT
            "年月"::VARCHAR AS "年月",
            SUM("実績合計") AS "実績",
            SUM("予算合計") AS "予算"
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
        WHERE ("会社" IN ({company_clause}) OR "会社" IS NULL)
          AND ("部門G" IN ({dept_clause}) OR "部門G" IS NULL)
        GROUP BY "年月"
        ORDER BY "年月"
    """)
    st.line_chart(monthly_pv_df, x="年月", y=["実績", "予算"])

    # 詳細テーブル
    st.subheader("詳細データ")
    detail_pv_df = session.sql(f"""
        SELECT *
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
        WHERE ("会社" IN ({company_clause}) OR "会社" IS NULL)
          AND ("部門G" IN ({dept_clause}) OR "部門G" IS NULL)
        ORDER BY "年月" DESC, "実績合計" DESC
        LIMIT 100
    """)
    st.dataframe(detail_pv_df, use_container_width=True)

# ==========================================================
# Tab 3: AI 自然言語問い合わせ
# ==========================================================
with tab3:
    st.header("AI データ問い合わせ")
    st.info(
        "Snowflake Cortex AI を活用して、自然言語でデータに関する質問ができます。\n"
        "例: 「2025年度の仕入高合計を媒体種類別に教えて」「予算達成率が低い部門は？」"
    )

    user_question = st.text_area(
        "データについて質問してください:",
        placeholder="例: 2025年度の仕入高が最も多い広告主業種は何ですか？",
        height=100,
    )

    if st.button("質問する", type="primary"):
        if user_question:
            with st.spinner("AI がデータを収集・分析中です..."):

                def rows_to_text(rows, cols):
                    lines = []
                    for r in rows:
                        parts = [f"{c}={r[c]}" for c in cols]
                        lines.append(" | ".join(parts))
                    return "\n".join(lines) if lines else "(データなし)"

                # --- View 1: 年度別 全体KPI ---
                v1 = session.sql("""
                    SELECT "年度_4月起点" AS "年度",
                           SUM("取引件数") AS "総取引件数",
                           SUM("仕入高合計") AS "仕入高計",
                           SUM("媒体収益合計") AS "媒体収益計",
                           SUM("媒体収益予算合計") AS "媒体収益予算計",
                           ROUND(SUM("媒体収益合計") / NULLIF(SUM("媒体収益予算合計"),0) * 100, 1) AS "予実達成率%",
                           ROUND(SUM("媒体収益合計") / NULLIF(SUM("仕入高合計"),0) * 100, 2) AS "収益率%",
                           SUM("FC営収合計") AS "FC営収計",
                           SUM("スタッフコスト合計") AS "スタッフコスト計"
                    FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
                    GROUP BY "年度_4月起点" ORDER BY "年度_4月起点"
                """).collect()
                t1 = rows_to_text(v1, ["年度","総取引件数","仕入高計","媒体収益計","媒体収益予算計","予実達成率%","収益率%","FC営収計","スタッフコスト計"])

                # --- View 2: 広告主業種別ランキング（全期間合算） ---
                v2 = session.sql("""
                    SELECT "広告主業種_大名" AS "業種",
                           SUM("仕入高合計") AS "仕入高計",
                           SUM("媒体収益合計") AS "媒体収益計",
                           ROUND(SUM("媒体収益合計") / NULLIF(SUM("仕入高合計"),0) * 100, 2) AS "収益率%",
                           SUM("取引件数") AS "取引件数"
                    FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
                    GROUP BY "広告主業種_大名" ORDER BY "仕入高計" DESC
                """).collect()
                t2 = rows_to_text(v2, ["業種","仕入高計","媒体収益計","収益率%","取引件数"])

                # --- View 3: メディア区分 × 媒体種類 クロス集計 ---
                v3 = session.sql("""
                    SELECT "マスメディア区分名" AS "メディア区分", "媒体種類名" AS "媒体種類",
                           SUM("仕入高合計") AS "仕入高計",
                           SUM("媒体収益合計") AS "媒体収益計",
                           ROUND(SUM("媒体収益合計") / NULLIF(SUM("仕入高合計"),0) * 100, 2) AS "収益率%"
                    FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
                    GROUP BY "マスメディア区分名", "媒体種類名" ORDER BY "仕入高計" DESC
                """).collect()
                t3 = rows_to_text(v3, ["メディア区分","媒体種類","仕入高計","媒体収益計","収益率%"])

                # --- View 4: 四半期トレンド（YoY比較用） ---
                v4 = session.sql("""
                    SELECT "年度_4月起点" AS "年度", "四半期_4月起点" AS "四半期",
                           SUM("仕入高合計") AS "仕入高計",
                           SUM("媒体収益合計") AS "媒体収益計",
                           ROUND(SUM("媒体収益合計") / NULLIF(SUM("媒体収益予算合計"),0) * 100, 1) AS "予実達成率%"
                    FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
                    GROUP BY "年度_4月起点", "四半期_4月起点"
                    ORDER BY "年度_4月起点", "四半期_4月起点"
                """).collect()
                t4 = rows_to_text(v4, ["年度","四半期","仕入高計","媒体収益計","予実達成率%"])

                # --- View 5: 代理店系列（H/D/Y）別パフォーマンス ---
                v5 = session.sql("""
                    SELECT AGENCY_KEY AS "代理店系列",
                           SUM("仕入高合計") AS "仕入高計",
                           SUM("媒体収益合計") AS "媒体収益計",
                           ROUND(SUM("媒体収益合計") / NULLIF(SUM("媒体収益予算合計"),0) * 100, 1) AS "予実達成率%",
                           ROUND(SUM("媒体収益合計") / NULLIF(SUM("仕入高合計"),0) * 100, 2) AS "収益率%"
                    FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
                    GROUP BY AGENCY_KEY ORDER BY "仕入高計" DESC
                """).collect()
                t5 = rows_to_text(v5, ["代理店系列","仕入高計","媒体収益計","予実達成率%","収益率%"])

                # --- View 6: 組織損益 — 会社×部門G×管理項目 ---
                v6 = session.sql("""
                    SELECT "会社", "部門G", "管理項目名称",
                           SUM("実績合計") AS "実績計",
                           SUM("予算合計") AS "予算計",
                           SUM("実績合計") - SUM("予算合計") AS "予実差異",
                           ROUND(SUM("実績合計") / NULLIF(SUM("予算合計"),0) * 100, 1) AS "達成率%"
                    FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
                    GROUP BY "会社", "部門G", "管理項目名称"
                    ORDER BY ABS(SUM("実績合計") - SUM("予算合計")) DESC
                    LIMIT 40
                """).collect()
                t6 = rows_to_text(v6, ["会社","部門G","管理項目名称","実績計","予算計","予実差異","達成率%"])

                # --- View 7: 組織損益 — 年度別推移 ---
                v7 = session.sql("""
                    SELECT "年度", "会社",
                           SUM("実績合計") AS "実績計",
                           SUM("予算合計") AS "予算計",
                           ROUND(SUM("実績合計") / NULLIF(SUM("予算合計"),0) * 100, 1) AS "達成率%"
                    FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
                    GROUP BY "年度", "会社"
                    ORDER BY "年度", "実績計" DESC
                """).collect()
                t7 = rows_to_text(v7, ["年度","会社","実績計","予算計","達成率%"])

                # --- プロンプト構築 ---
                context = f"""あなたは博報堂DYグループの経営企画部門に所属するシニアデータアナリストです。
広告業界の専門知識（メディアバイイング、媒体収益構造、予実管理）を持ち、経営層への報告を行う立場です。

## 回答フォーマット（必ずこの構成で出力すること）

### 結論
- 質問に対する直接的な回答を1-3文で述べる

### 数値根拠
- 根拠となるデータを表形式またはリストで提示する
- 金額は億円・万円単位に換算（例: 35,942,425 → 約3,594万円）
- 比率・達成率は%で明記

### 比較分析
- 前年度比較（YoY増減率を算出）
- セグメント間比較（上位/下位の差、構成比）
- 四半期推移の傾向（成長/鈍化/季節性）

### ビジネス示唆
- データから導かれる経営判断に有用な示唆を2-3点
- リスク要因があれば警告として明記

## 厳守ルール
- 必ず提供データの実数値を引用すること。推測や一般論は不可。
- SQLクエリやコードは絶対に出力しないこと。
- 複数の切り口（業種別、メディア別、四半期別、代理店系列別）から多角的に分析すること。
- 提供データに回答に必要な情報がない場合は「提供データの範囲では判断できません」と明記すること。

=== データ期間: 2023年4月〜2025年4月（年度は4月起点） ===

【View 1: 年度別 全体KPI】
項目: 年度, 総取引件数, 仕入高計, 媒体収益計, 媒体収益予算計, 予実達成率%, 収益率%, FC営収計, スタッフコスト計
{t1}

【View 2: 広告主業種別ランキング（全期間合算）】
項目: 業種, 仕入高計, 媒体収益計, 収益率%, 取引件数
{t2}

【View 3: メディア区分 × 媒体種類 クロス集計】
項目: メディア区分, 媒体種類, 仕入高計, 媒体収益計, 収益率%
{t3}

【View 4: 四半期トレンド（年度×四半期）】
項目: 年度, 四半期, 仕入高計, 媒体収益計, 予実達成率%
{t4}

【View 5: 代理店系列別パフォーマンス（H=博報堂, D=大広, Y=読広）】
項目: 代理店系列, 仕入高計, 媒体収益計, 予実達成率%, 収益率%
{t5}

【View 6: 組織損益 — 予実乖離が大きい順（会社×部門G×管理項目）】
項目: 会社, 部門G, 管理項目名称, 実績計, 予算計, 予実差異, 達成率%
{t6}

【View 7: 組織損益 — 年度×会社別推移】
項目: 年度, 会社, 実績計, 予算計, 達成率%
{t7}

質問: {user_question}"""

                escaped = context.replace("\\", "\\\\").replace("'", "''")

                result = session.sql(
                    f"SELECT SNOWFLAKE.CORTEX.COMPLETE('claude-4-sonnet', '{escaped}') AS RESPONSE"
                ).collect()

                answer = str(result[0]["RESPONSE"])
                st.markdown("### 分析結果")
                st.markdown(answer)

                st.divider()
                st.markdown("### 参考: 直近の仕入月次サマリ（上位20件）")
                ref_df = session.sql("""
                    SELECT "年月", "会社_営業_名_最新", "広告主業種_大名",
                           "仕入高合計", "媒体収益合計", "媒体収益予算合計"
                    FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
                    ORDER BY "年月" DESC, "仕入高合計" DESC
                    LIMIT 20
                """)
                st.dataframe(ref_df, use_container_width=True)
        else:
            st.warning("質問を入力してください。")
