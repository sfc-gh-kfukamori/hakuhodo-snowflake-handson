-- ============================================================================
-- 博報堂 Snowflake ハンズオン
-- Section 4: Streamlit in Snowflake ダッシュボード
-- ============================================================================
-- このセクションでは以下を学びます:
--   1. Streamlit in Snowflake (SiS) でダッシュボードアプリを作成
--   2. 加工済みデータの可視化（チャート・テーブル）
--   3. Cortex AI Function を使った自然言語問い合わせ機能
--
-- ★ Streamlit in Snowflake とは:
--   Snowflake 上で Python ベースの Web アプリを直接実行できる機能です。
--   データの移動なしにセキュアなダッシュボードを構築できます。
--
-- ★ 重要: このセクションでは Snowsight GUI からアプリを作成します。
--   CREATE STREAMLIT SQL ではなく、GUI から作成する方が確実に動作します。
-- ============================================================================

USE ROLE SYSADMIN;
USE DATABASE HAKUHODO_HANDSON_DB;
USE WAREHOUSE HAKUHODO_HANDSON_WH;

-- ============================================================================
-- Step 4-1: Streamlit アプリの作成（Snowsight GUI）
-- ============================================================================
-- ★ Snowsight での作成手順:
--
--   1. Snowsight にログイン
--   2. 左メニュー「Projects & Resources」→「Streamlit」を選択
--   3. 右上の「+ Streamlit App」ボタンをクリック
--   4. 以下を設定:
--      - App title: HAKUHODO_DASHBOARD
--      - App location:
--          Database: HAKUHODO_HANDSON_DB
--          Schema:   STREAMLIT
--      - App warehouse: HAKUHODO_HANDSON_WH
--   5. 「Create」をクリック
--   6. エディタが開いたら、デフォルトのコードを全て削除（Cmd+A → Delete）
--   7. 下記の Python コードを貼り付け
--   8. 「Run」ボタンをクリック
--
-- ★ ポイント:
--   - GUI から作成すると、ステージの作成やファイルアップロードが不要
--   - エディタ上でコードを直接編集・実行できるため、開発サイクルが速い
--   - パッケージの追加も左パネルから可能
-- ============================================================================

-- ============================================================================
-- Step 4-2: 貼り付ける Python コード
-- ============================================================================
-- 以下のコードをエディタに貼り付けてください。
-- ★ 3つのタブで構成されています:
--   - タブ1「仕入分析」: KPI・月別チャート・媒体種類別チャート・詳細テーブル
--   - タブ2「組織損益分析」: 予算vs実績チャート・月次推移・詳細テーブル
--   - タブ3「AI問い合わせ」: Cortex AI で自然言語データ分析
-- ============================================================================

/*
---- ここから Python コード（エディタに貼り付け） ----

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
                v1 = session.sql(\"\"\"
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
                \"\"\").collect()
                t1 = rows_to_text(v1, ["年度","総取引件数","仕入高計","媒体収益計","媒体収益予算計","予実達成率%","収益率%","FC営収計","スタッフコスト計"])

                # --- View 2〜7 は同様に集計（コード全文は streamlit/hakuhodo_dashboard.py を参照）---
                # （省略 — 実際のコードでは7つのViewを全て含めます）

                # ... AI プロンプト構築・実行 ...

        else:
            st.warning("質問を入力してください。")

---- ここまで Python コード ----
*/

-- ============================================================================
-- Step 4-3: Streamlit アプリの動作確認
-- ============================================================================
-- ★ 確認ポイント:
--   - 「仕入分析」タブ: フィルタを変更するとKPI・チャートが連動して更新される
--   - 「組織損益分析」タブ: 会社・部門でフィルタし予算 vs 実績が比較できる
--   - 「AI 問い合わせ」タブ: 自然言語で質問すると実データに基づく分析結果が返る
--     例: 「仕入高が最も多い媒体種類は？」
--     例: 「予算達成率が低い部門を教えて」
--     例: 「2024年度と2023年度の仕入高を比較して」
--
-- ★ 完全なPythonコードは以下のGitHubリポジトリに格納されています:
--   streamlit/hakuhodo_dashboard.py
--   https://github.com/sfc-gh-kfukamori/hakuhodo-snowflake-handson

-- ============================================================================
-- ★ 学びのポイント:
--   - Streamlit in Snowflake はデータ移動なしでダッシュボードを構築できる
--   - Snowsight GUI から作成するのが最もシンプルで確実
--   - Snowpark セッションで直接 SQL を実行しデータを取得
--   - collect() でデータ取得、Snowpark DataFrame を直接チャートに渡せる
--   - Cortex AI Function (COMPLETE) を組み込むことで、
--     非エンジニアでも自然言語でデータ分析が可能に
--   - アクセス権は Snowflake のロールベースで自動管理される
-- ============================================================================
-- 次のステップ: 05_snowflake_intelligence.sql に進んでください
-- ============================================================================
