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
-- ============================================================================

USE ROLE SYSADMIN;
USE DATABASE HAKUHODO_HANDSON_DB;
USE SCHEMA STREAMLIT;
USE WAREHOUSE HAKUHODO_HANDSON_WH;

-- ============================================================================
-- Step 4-1: Streamlit アプリの作成
-- ============================================================================
-- CREATE STREAMLIT コマンドでアプリを定義します。
-- MAIN_FILE にはアプリの Python コードをインラインで記述します。

CREATE OR REPLACE STREAMLIT HAKUHODO_HANDSON_DB.STREAMLIT.HAKUHODO_DASHBOARD
    ROOT_LOCATION = '@HAKUHODO_HANDSON_DB.STREAMLIT.STREAMLIT_STAGE'
    MAIN_FILE = 'hakuhodo_dashboard.py'
    QUERY_WAREHOUSE = HAKUHODO_HANDSON_WH
    COMMENT = '博報堂ハンズオン ダッシュボード（AI問い合わせ機能付き）';

-- ============================================================================
-- Step 4-2: ステージとアプリファイルの準備
-- ============================================================================
-- Streamlit アプリのソースコードを格納するステージを作成します。

CREATE STAGE IF NOT EXISTS HAKUHODO_HANDSON_DB.STREAMLIT.STREAMLIT_STAGE
    COMMENT = 'Streamlit アプリ用ステージ';

-- ============================================================================
-- Step 4-3: Streamlit アプリのソースコード
-- ============================================================================
-- 以下の Python コードを hakuhodo_dashboard.py としてステージにアップロードしてください。
-- Snowsight の Streamlit エディタに直接貼り付けることも可能です。
--
-- ★ Snowsight からの作成方法:
--   1. Snowsight にログイン
--   2. 左メニュー「Streamlit」→「+ Streamlit App」
--   3. Database: HAKUHODO_HANDSON_DB, Schema: STREAMLIT を選択
--   4. Warehouse: HAKUHODO_HANDSON_WH を選択
--   5. 以下の Python コードをエディタに貼り付けて「Run」
-- ============================================================================

-- ★★★ 以下が hakuhodo_dashboard.py の内容です ★★★
-- ============================================================================
/*
---- hakuhodo_dashboard.py ここから ----

import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd

# --------------------------------------------------
# セッション取得
# --------------------------------------------------
session = get_active_session()

# --------------------------------------------------
# ページ設定
# --------------------------------------------------
st.set_page_config(page_title="博報堂 データダッシュボード", layout="wide")
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

    # --- フィルタ ---
    col_f1, col_f2, col_f3 = st.columns(3)

    # 年月の選択肢を取得
    ym_df = session.sql('''
        SELECT DISTINCT "年月"
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
        ORDER BY "年月" DESC
    ''').to_pandas()

    with col_f1:
        selected_ym = st.multiselect(
            "年月",
            options=ym_df["年月"].tolist(),
            default=ym_df["年月"].tolist()[:3] if len(ym_df) >= 3 else ym_df["年月"].tolist()
        )

    # 代理店系列の選択
    agency_df = session.sql('''
        SELECT DISTINCT AGENCY_KEY
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
        WHERE AGENCY_KEY IS NOT NULL
        ORDER BY AGENCY_KEY
    ''').to_pandas()

    with col_f2:
        selected_agency = st.multiselect(
            "代理店系列",
            options=agency_df["AGENCY_KEY"].tolist(),
            default=agency_df["AGENCY_KEY"].tolist()
        )

    # マスメディア区分の選択
    media_df = session.sql('''
        SELECT DISTINCT "マスメディア区分名"
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
        WHERE "マスメディア区分名" IS NOT NULL
        ORDER BY "マスメディア区分名"
    ''').to_pandas()

    with col_f3:
        selected_media = st.multiselect(
            "マスメディア区分",
            options=media_df["マスメディア区分名"].tolist(),
            default=media_df["マスメディア区分名"].tolist()
        )

    # --- フィルタ条件の構築 ---
    ym_list = ",".join([str(y) for y in selected_ym]) if selected_ym else "0"
    agency_list = ",".join([f"'{a}'" for a in selected_agency]) if selected_agency else "''"
    media_list = ",".join([f"'{m}'" for m in selected_media]) if selected_media else "''"

    # --- KPI カード ---
    kpi_query = f'''
        SELECT
            SUM("仕入高合計") AS total_purchase,
            SUM("媒体収益合計") AS total_revenue,
            SUM("媒体収益予算合計") AS total_budget,
            SUM("FC営収合計") AS total_fc,
            SUM("取引件数") AS total_deals
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
        WHERE "年月" IN ({ym_list})
          AND (AGENCY_KEY IN ({agency_list}) OR AGENCY_KEY IS NULL)
          AND ("マスメディア区分名" IN ({media_list}) OR "マスメディア区分名" IS NULL)
    '''
    kpi_df = session.sql(kpi_query).to_pandas()

    col1, col2, col3, col4 = st.columns(4)
    with col1:
        val = kpi_df["TOTAL_PURCHASE"].iloc[0] or 0
        st.metric("仕入高合計", f"¥{val:,.0f}")
    with col2:
        val = kpi_df["TOTAL_REVENUE"].iloc[0] or 0
        st.metric("媒体収益合計", f"¥{val:,.0f}")
    with col3:
        budget = kpi_df["TOTAL_BUDGET"].iloc[0] or 0
        revenue = kpi_df["TOTAL_REVENUE"].iloc[0] or 0
        rate = (revenue / budget * 100) if budget else 0
        st.metric("予実達成率", f"{rate:.1f}%")
    with col4:
        val = kpi_df["TOTAL_DEALS"].iloc[0] or 0
        st.metric("取引件数", f"{val:,.0f}")

    st.divider()

    # --- チャート ---
    col_c1, col_c2 = st.columns(2)

    with col_c1:
        st.subheader("月別 仕入高推移")
        monthly_query = f'''
            SELECT "年月",
                   SUM("仕入高合計") AS "仕入高",
                   SUM("媒体収益合計") AS "媒体収益"
            FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
            WHERE "年月" IN ({ym_list})
              AND (AGENCY_KEY IN ({agency_list}) OR AGENCY_KEY IS NULL)
            GROUP BY "年月"
            ORDER BY "年月"
        '''
        monthly_df = session.sql(monthly_query).to_pandas()
        monthly_df["年月"] = monthly_df["年月"].astype(str)
        st.bar_chart(monthly_df.set_index("年月"))

    with col_c2:
        st.subheader("媒体種類別 仕入高構成")
        media_type_query = f'''
            SELECT "媒体種類名",
                   SUM("仕入高合計") AS "仕入高"
            FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
            WHERE "年月" IN ({ym_list})
              AND (AGENCY_KEY IN ({agency_list}) OR AGENCY_KEY IS NULL)
              AND "媒体種類名" IS NOT NULL
            GROUP BY "媒体種類名"
            ORDER BY "仕入高" DESC
            LIMIT 10
        '''
        media_type_df = session.sql(media_type_query).to_pandas()
        st.bar_chart(media_type_df.set_index("媒体種類名"))

    # --- 詳細テーブル ---
    st.subheader("詳細データ")
    detail_query = f'''
        SELECT *
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
        WHERE "年月" IN ({ym_list})
          AND (AGENCY_KEY IN ({agency_list}) OR AGENCY_KEY IS NULL)
          AND ("マスメディア区分名" IN ({media_list}) OR "マスメディア区分名" IS NULL)
        ORDER BY "年月" DESC, "仕入高合計" DESC
        LIMIT 100
    '''
    detail_df = session.sql(detail_query).to_pandas()
    st.dataframe(detail_df, use_container_width=True)

# ==========================================================
# Tab 2: 組織損益分析
# ==========================================================
with tab2:
    st.header("組織損益分析（予算 vs 実績）")

    # --- フィルタ ---
    col_o1, col_o2 = st.columns(2)

    company_df = session.sql('''
        SELECT DISTINCT "会社"
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
        WHERE "会社" IS NOT NULL ORDER BY "会社"
    ''').to_pandas()

    with col_o1:
        selected_company = st.multiselect(
            "会社",
            options=company_df["会社"].tolist(),
            default=company_df["会社"].tolist()
        )

    dept_df = session.sql('''
        SELECT DISTINCT "部門G"
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
        WHERE "部門G" IS NOT NULL ORDER BY "部門G"
    ''').to_pandas()

    with col_o2:
        selected_dept = st.multiselect(
            "部門グループ",
            options=dept_df["部門G"].tolist(),
            default=dept_df["部門G"].tolist()
        )

    company_list = ",".join([f"'{c}'" for c in selected_company]) if selected_company else "''"
    dept_list = ",".join([f"'{d}'" for d in selected_dept]) if selected_dept else "''"

    # --- 予実比較チャート ---
    st.subheader("管理項目別 予算 vs 実績")
    pv_query = f'''
        SELECT
            "管理項目名称",
            SUM("実績合計") AS "実績",
            SUM("予算合計") AS "予算"
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
        WHERE ("会社" IN ({company_list}) OR "会社" IS NULL)
          AND ("部門G" IN ({dept_list}) OR "部門G" IS NULL)
        GROUP BY "管理項目名称"
        HAVING SUM("予算合計") <> 0
        ORDER BY "実績" DESC
        LIMIT 15
    '''
    pv_df = session.sql(pv_query).to_pandas()
    st.bar_chart(pv_df.set_index("管理項目名称"))

    # --- 月次推移 ---
    st.subheader("月次 予実推移")
    monthly_pv_query = f'''
        SELECT
            "年月",
            SUM("実績合計") AS "実績",
            SUM("予算合計") AS "予算",
            SUM("予実差異") AS "差異"
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
        WHERE ("会社" IN ({company_list}) OR "会社" IS NULL)
          AND ("部門G" IN ({dept_list}) OR "部門G" IS NULL)
        GROUP BY "年月"
        ORDER BY "年月"
    '''
    monthly_pv_df = session.sql(monthly_pv_query).to_pandas()
    monthly_pv_df["年月"] = monthly_pv_df["年月"].astype(str)
    st.line_chart(monthly_pv_df.set_index("年月")[["実績", "予算"]])

    # --- 詳細テーブル ---
    st.subheader("詳細データ")
    detail_pv_query = f'''
        SELECT *
        FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
        WHERE ("会社" IN ({company_list}) OR "会社" IS NULL)
          AND ("部門G" IN ({dept_list}) OR "部門G" IS NULL)
        ORDER BY "年月" DESC, "実績合計" DESC
        LIMIT 100
    '''
    detail_pv_df = session.sql(detail_pv_query).to_pandas()
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

    # ユーザーの質問入力
    user_question = st.text_area(
        "データについて質問してください:",
        placeholder="例: 2025年度の仕入高が最も多い広告主業種は何ですか？",
        height=100
    )

    if st.button("質問する", type="primary"):
        if user_question:
            with st.spinner("AI が分析中です..."):

                # テーブル情報をコンテキストとして渡す
                context_prompt = f"""
あなたはSnowflakeのデータアナリストです。以下のテーブル情報を元に、ユーザーの質問に日本語で回答してください。

## 利用可能テーブル

### HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
月次仕入集計データ。カラム: 年度_4月起点, 年月, 四半期_4月起点, 会社_営業_名_最新, 広告主業種_大名, マスメディア区分名, 媒体種類名, AGENCY_KEY(H:博報堂/D:大広/Y:読広), 取引件数, 仕入高合計, 媒体収益合計, 媒体収益予算合計, 媒体収益予実差異, FC営収合計, スタッフコスト合計

### HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
組織損益集計データ。カラム: 年度, 年月, 四半期, 会社, 部門G, 部門, 管理項目名称, 実績合計, 予算合計, 予実差異, 予実達成率

## ユーザーの質問
{user_question}

質問に対する分析結果を簡潔に日本語で回答してください。必要であればSQLクエリも提示してください。
"""

                # Cortex COMPLETE で回答を生成
                response_df = session.sql(f"""
                    SELECT SNOWFLAKE.CORTEX.COMPLETE(
                        'claude-3-5-sonnet',
                        '{context_prompt.replace("'", "''")}'
                    ) AS response
                """).to_pandas()

                answer = response_df["RESPONSE"].iloc[0]
                st.markdown("### 回答")
                st.markdown(answer)

                # 関連データのプレビューを表示
                st.divider()
                st.markdown("### 参考データ（直近の仕入月次サマリ）")
                ref_df = session.sql('''
                    SELECT "年月", "会社_営業_名_最新", "広告主業種_大名",
                           "仕入高合計", "媒体収益合計", "媒体収益予算合計"
                    FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
                    ORDER BY "年月" DESC, "仕入高合計" DESC
                    LIMIT 20
                ''').to_pandas()
                st.dataframe(ref_df, use_container_width=True)
        else:
            st.warning("質問を入力してください。")

---- hakuhodo_dashboard.py ここまで ----
*/

-- ============================================================================
-- Step 4-4: Streamlit アプリの動作確認
-- ============================================================================
-- ★ Snowsight で確認:
--   1. 左メニュー「Streamlit」を開く
--   2. HAKUHODO_DASHBOARD が表示されていることを確認
--   3. クリックしてアプリを起動
--
-- ★ 確認ポイント:
--   - 「仕入分析」タブでフィルタを変更するとチャートが連動して更新される
--   - 「組織損益分析」タブで予算 vs 実績が比較できる
--   - 「AI 問い合わせ」タブで自然言語による質問ができる
--     例: 「仕入高が最も多い媒体種類は？」
--     例: 「予算達成率が低い部門を教えて」
-- ============================================================================

-- Streamlit アプリが作成されていることを確認
SHOW STREAMLITS IN SCHEMA HAKUHODO_HANDSON_DB.STREAMLIT;

-- ============================================================================
-- ★ 学びのポイント:
--   - Streamlit in Snowflake はデータ移動なしでダッシュボードを構築できる
--   - Snowpark セッションで直接 SQL を実行しデータを取得
--   - Cortex AI Function (COMPLETE) を組み込むことで、
--     非エンジニアでも自然言語でデータ分析が可能に
--   - アクセス権は Snowflake のロールベースで自動管理される
-- ============================================================================
-- 次のステップ: 05_snowflake_intelligence.sql に進んでください
-- ============================================================================
