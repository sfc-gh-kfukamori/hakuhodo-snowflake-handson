import streamlit as st
from snowflake.snowpark.context import get_active_session

session = get_active_session()

st.title("博報堂 データダッシュボード")
st.caption("Snowflake ハンズオン — Streamlit in Snowflake + Cortex AI")

# --------------------------------------------------
# データ件数の確認（最小動作テスト）
# --------------------------------------------------
st.header("データ確認")

count_df = session.sql("""
    SELECT
        (SELECT COUNT(*) FROM HAKUHODO_HANDSON_DB.HAKUHODO_HANDSON_SCHEMA.PURCHASE_NEW_TABLE) AS PURCHASE_COUNT,
        (SELECT COUNT(*) FROM HAKUHODO_HANDSON_DB.HAKUHODO_HANDSON_SCHEMA.SPECIAL_FEE_TABLE) AS FEE_COUNT,
        (SELECT COUNT(*) FROM HAKUHODO_HANDSON_DB.HAKUHODO_HANDSON_SCHEMA.MST_AGENCY_GROUP) AS AGENCY_COUNT
""").collect()

row = count_df[0]
c1, c2, c3 = st.columns(3)
c1.metric("仕入データ", f"{row['PURCHASE_COUNT']:,} 件")
c2.metric("組織損益データ", f"{row['FEE_COUNT']:,} 件")
c3.metric("代理店マスタ", f"{row['AGENCY_COUNT']:,} 件")

# --------------------------------------------------
# タブ構成
# --------------------------------------------------
tab1, tab2, tab3 = st.tabs(["仕入分析", "組織損益分析", "AI 問い合わせ"])

# ==========================================================
# Tab 1: 仕入分析
# ==========================================================
with tab1:
    st.header("仕入データ分析")

    # フィルタ用の選択肢を collect() で取得（to_pandas を避ける）
    ym_rows = session.sql('''
        SELECT DISTINCT "年月"
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
        ORDER BY "年月" DESC
    ''').collect()
    ym_options = [int(r["年月"]) for r in ym_rows]

    agency_rows = session.sql('''
        SELECT DISTINCT AGENCY_KEY
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
        WHERE AGENCY_KEY IS NOT NULL
        ORDER BY AGENCY_KEY
    ''').collect()
    agency_options = [r["AGENCY_KEY"] for r in agency_rows]

    media_rows = session.sql('''
        SELECT DISTINCT "マスメディア区分名"
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
        WHERE "マスメディア区分名" IS NOT NULL
        ORDER BY "マスメディア区分名"
    ''').collect()
    media_options = [r["マスメディア区分名"] for r in media_rows]

    # フィルタ
    col_f1, col_f2, col_f3 = st.columns(3)
    with col_f1:
        selected_ym = st.multiselect("年月", options=ym_options, default=ym_options[:3])
    with col_f2:
        selected_agency = st.multiselect("代理店系列", options=agency_options, default=agency_options)
    with col_f3:
        selected_media = st.multiselect("マスメディア区分", options=media_options, default=media_options)

    # フィルタ条件構築
    ym_clause = ",".join([str(y) for y in selected_ym]) if selected_ym else "0"
    agency_clause = ",".join([f"'{a}'" for a in selected_agency]) if selected_agency else "''"
    media_clause = ",".join([f"'{m}'" for m in selected_media]) if selected_media else "''"

    # KPI
    kpi_rows = session.sql(f'''
        SELECT
            COALESCE(SUM("仕入高合計"), 0) AS TOTAL_PURCHASE,
            COALESCE(SUM("媒体収益合計"), 0) AS TOTAL_REVENUE,
            COALESCE(SUM("媒体収益予算合計"), 0) AS TOTAL_BUDGET,
            COALESCE(SUM("取引件数"), 0) AS TOTAL_DEALS
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
        WHERE "年月" IN ({ym_clause})
          AND (AGENCY_KEY IN ({agency_clause}) OR AGENCY_KEY IS NULL)
          AND ("マスメディア区分名" IN ({media_clause}) OR "マスメディア区分名" IS NULL)
    ''').collect()

    kpi = kpi_rows[0]
    k1, k2, k3, k4 = st.columns(4)
    k1.metric("仕入高合計", f"¥{int(kpi['TOTAL_PURCHASE']):,}")
    k2.metric("媒体収益合計", f"¥{int(kpi['TOTAL_REVENUE']):,}")
    budget_val = int(kpi['TOTAL_BUDGET'])
    revenue_val = int(kpi['TOTAL_REVENUE'])
    rate = round(revenue_val / budget_val * 100, 1) if budget_val else 0
    k3.metric("予実達成率", f"{rate}%")
    k4.metric("取引件数", f"{int(kpi['TOTAL_DEALS']):,}")

    st.divider()

    # 月別仕入高推移
    col_c1, col_c2 = st.columns(2)
    with col_c1:
        st.subheader("月別 仕入高推移")
        monthly_df = session.sql(f'''
            SELECT "年月"::VARCHAR AS "年月",
                   SUM("仕入高合計") AS "仕入高",
                   SUM("媒体収益合計") AS "媒体収益"
            FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
            WHERE "年月" IN ({ym_clause})
              AND (AGENCY_KEY IN ({agency_clause}) OR AGENCY_KEY IS NULL)
            GROUP BY "年月"
            ORDER BY "年月"
        ''')
        st.bar_chart(monthly_df, x="年月", y=["仕入高", "媒体収益"])

    with col_c2:
        st.subheader("媒体種類別 仕入高構成")
        media_type_df = session.sql(f'''
            SELECT "媒体種類名",
                   SUM("仕入高合計") AS "仕入高"
            FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
            WHERE "年月" IN ({ym_clause})
              AND (AGENCY_KEY IN ({agency_clause}) OR AGENCY_KEY IS NULL)
              AND "媒体種類名" IS NOT NULL
            GROUP BY "媒体種類名"
            ORDER BY "仕入高" DESC
            LIMIT 10
        ''')
        st.bar_chart(media_type_df, x="媒体種類名", y="仕入高")

    # 詳細テーブル
    st.subheader("詳細データ")
    detail_df = session.sql(f'''
        SELECT *
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
        WHERE "年月" IN ({ym_clause})
          AND (AGENCY_KEY IN ({agency_clause}) OR AGENCY_KEY IS NULL)
          AND ("マスメディア区分名" IN ({media_clause}) OR "マスメディア区分名" IS NULL)
        ORDER BY "年月" DESC, "仕入高合計" DESC
        LIMIT 100
    ''')
    st.dataframe(detail_df, use_container_width=True)

# ==========================================================
# Tab 2: 組織損益分析
# ==========================================================
with tab2:
    st.header("組織損益分析（予算 vs 実績）")

    # フィルタ
    company_rows = session.sql('''
        SELECT DISTINCT "会社"
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
        WHERE "会社" IS NOT NULL ORDER BY "会社"
    ''').collect()
    company_options = [r["会社"] for r in company_rows]

    dept_rows = session.sql('''
        SELECT DISTINCT "部門G"
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
        WHERE "部門G" IS NOT NULL ORDER BY "部門G"
    ''').collect()
    dept_options = [r["部門G"] for r in dept_rows]

    col_o1, col_o2 = st.columns(2)
    with col_o1:
        selected_company = st.multiselect("会社", options=company_options, default=company_options)
    with col_o2:
        selected_dept = st.multiselect("部門グループ", options=dept_options, default=dept_options)

    company_clause = ",".join([f"'{c}'" for c in selected_company]) if selected_company else "''"
    dept_clause = ",".join([f"'{d}'" for d in selected_dept]) if selected_dept else "''"

    # 予実比較チャート
    st.subheader("管理項目別 予算 vs 実績")
    pv_df = session.sql(f'''
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
    ''')
    st.bar_chart(pv_df, x="管理項目名称", y=["実績", "予算"])

    # 月次推移
    st.subheader("月次 予実推移")
    monthly_pv_df = session.sql(f'''
        SELECT
            "年月"::VARCHAR AS "年月",
            SUM("実績合計") AS "実績",
            SUM("予算合計") AS "予算"
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
        WHERE ("会社" IN ({company_clause}) OR "会社" IS NULL)
          AND ("部門G" IN ({dept_clause}) OR "部門G" IS NULL)
        GROUP BY "年月"
        ORDER BY "年月"
    ''')
    st.line_chart(monthly_pv_df, x="年月", y=["実績", "予算"])

    # 詳細テーブル
    st.subheader("詳細データ")
    detail_pv_df = session.sql(f'''
        SELECT *
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
        WHERE ("会社" IN ({company_clause}) OR "会社" IS NULL)
          AND ("部門G" IN ({dept_clause}) OR "部門G" IS NULL)
        ORDER BY "年月" DESC, "実績合計" DESC
        LIMIT 100
    ''')
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
        height=100
    )

    if st.button("質問する", type="primary"):
        if user_question:
            with st.spinner("AI が分析中です..."):
                context = (
                    "あなたはSnowflakeのデータアナリストです。以下のテーブル情報を元に、"
                    "ユーザーの質問に日本語で回答してください。"
                    " テーブル1: HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY"
                    " (月次仕入集計。カラム: 年度_4月起点, 年月, 四半期_4月起点,"
                    " 会社_営業_名_最新, 広告主業種_大名, マスメディア区分名, 媒体種類名,"
                    " AGENCY_KEY, 取引件数, 仕入高合計, 媒体収益合計, 媒体収益予算合計,"
                    " FC営収合計, スタッフコスト合計)"
                    " テーブル2: HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY"
                    " (組織損益集計。カラム: 年度, 年月, 四半期, 会社, 部門G, 部門,"
                    " 管理項目名称, 実績合計, 予算合計, 予実差異, 予実達成率)"
                    " 質問: " + user_question
                )
                escaped = context.replace("\\", "\\\\").replace("'", "''")

                result = session.sql(
                    f"SELECT SNOWFLAKE.CORTEX.COMPLETE('claude-3-5-sonnet', '{escaped}') AS RESPONSE"
                ).collect()

                answer = str(result[0]["RESPONSE"])
                st.markdown("### 回答")
                st.markdown(answer)

                st.divider()
                st.markdown("### 参考データ（直近の仕入月次サマリ）")
                ref_df = session.sql('''
                    SELECT "年月", "会社_営業_名_最新", "広告主業種_大名",
                           "仕入高合計", "媒体収益合計", "媒体収益予算合計"
                    FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
                    ORDER BY "年月" DESC, "仕入高合計" DESC
                    LIMIT 20
                ''')
                st.dataframe(ref_df, use_container_width=True)
        else:
            st.warning("質問を入力してください。")
