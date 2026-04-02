# Snowflake ハンズオン — 博報堂

Snowflake の主要機能を体験するハンズオンコンテンツです。

## 構成

```
├── data/                          サンプルCSVデータ
│   ├── purchase_new_table/        仕入RAWデータ（4ファイル x 2,500行）
│   ├── special_fee_table/         組織損益RAWデータ（4ファイル x 2,500行）
│   └── mst_agency_group/          代理店グループマスタ（2ファイル x 15行）
├── sql/                           ハンズオンSQLスクリプト
│   ├── 00_setup.sql               環境セットアップ
│   ├── 01_external_stage_and_load.sql  GCS外部ステージ & データロード
│   ├── 02_data_engineering_stream_task.sql  Stream/Task
│   ├── 03_data_engineering_dynamic_table.sql  Dynamic Table
│   ├── 04_streamlit_dashboard.sql  Streamlit in Snowflake
│   ├── 05_snowflake_intelligence.sql  Snowflake Intelligence
│   ├── 06_ai_functions.sql        AI Function 活用例
│   └── 07_git_integration.sql     Git Integration セットアップ
├── streamlit/
│   └── hakuhodo_dashboard.py      Streamlit アプリ本体
└── semantic_model/
    └── hakuhodo_semantic_model.yaml  Semantic Model 定義
```

## 実行順序

1. `00_setup.sql` — DB/Schema/Warehouse作成
2. `07_git_integration.sql` — Git Integration セットアップ（Git経由でロードする場合）
3. `01_external_stage_and_load.sql` — データロード + WHサイズ比較
4. `02_data_engineering_stream_task.sql` — Stream/Taskパイプライン
5. `03_data_engineering_dynamic_table.sql` — Dynamic Tableパイプライン
6. `04_streamlit_dashboard.sql` — ダッシュボード構築
7. `05_snowflake_intelligence.sql` — Snowflake Intelligence
8. `06_ai_functions.sql` — AI Function活用例

## 前提条件

- Snowflake アカウント（SYSADMIN / ACCOUNTADMIN ロール）
- GCS バケット（外部ステージ用）またはこのGitリポジトリ経由でのデータロード
