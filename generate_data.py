#!/usr/bin/env python3
"""博報堂ハンズオン用CSVサンプルデータ生成スクリプト"""

import csv
import os
import random

random.seed(42)

BASE_DIR = "/Users/kfukamori/hakuhodo-snowflake-handson/data"

# ============================================================
# マスタデータ定義
# ============================================================

# 代理店グループマスタ
AGENCIES = [
    ("H001", "株式会社博報堂", "H"),
    ("H002", "株式会社博報堂DYメディアパートナーズ", "H"),
    ("H003", "株式会社博報堂プロダクツ", "H"),
    ("H004", "株式会社博報堂コンサルティング", "H"),
    ("H005", "株式会社博報堂DYデジタル", "H"),
    ("H006", "株式会社博報堂DYアウトドア", "H"),
    ("H007", "株式会社博報堂DYスポーツマーケティング", "H"),
    ("H008", "デジタル・アドバタイジング・コンソーシアム株式会社", "H"),
    ("H009", "株式会社アイレップ", "H"),
    ("H010", "株式会社博報堂DYホールディングス", "H"),
    ("D001", "株式会社大広", "D"),
    ("D002", "株式会社大広WEDO", "D"),
    ("D003", "株式会社大広九州", "D"),
    ("D004", "株式会社大広北海道", "D"),
    ("D005", "株式会社大広メディアックス", "D"),
    ("Y001", "株式会社読売広告社", "Y"),
    ("Y002", "株式会社読広クロスコム", "Y"),
    ("Y003", "株式会社読広プランニング", "Y"),
    ("Y004", "株式会社ユニバーサルコミュニケーションズ", "Y"),
    ("Y005", "株式会社読広エージェンシー", "Y"),
    ("E001", "株式会社kyu", "H"),
    ("E002", "株式会社SYパートナーズ", "H"),
    ("E003", "株式会社博報堂マーケティングシステムズ", "H"),
    ("E004", "株式会社スパイスボックス", "H"),
    ("E005", "株式会社エムハンド", "D"),
    ("E006", "株式会社コスモ・コミュニケーションズ", "Y"),
    ("E007", "株式会社博報堂アイ・スタジオ", "H"),
    ("E008", "株式会社博報堂テクノロジーズ", "H"),
    ("E009", "株式会社大広ONES", "D"),
    ("E010", "株式会社読広インターナショナル", "Y"),
]

# 営業部門
SALES_DEPTS = [
    ("SD01", "第一営業本部", "SD01-01", "第一営業部"),
    ("SD01", "第一営業本部", "SD01-02", "第二営業部"),
    ("SD02", "第二営業本部", "SD02-01", "第三営業部"),
    ("SD02", "第二営業本部", "SD02-02", "第四営業部"),
    ("SD03", "デジタル営業本部", "SD03-01", "デジタル第一営業部"),
    ("SD03", "デジタル営業本部", "SD03-02", "デジタル第二営業部"),
    ("SD04", "メディア営業本部", "SD04-01", "メディア営業部"),
    ("SD04", "メディア営業本部", "SD04-02", "メディアプランニング部"),
    ("SD05", "関西営業本部", "SD05-01", "関西第一営業部"),
    ("SD05", "関西営業本部", "SD05-02", "関西第二営業部"),
]

# G発注元
ORDERING_DEPTS = [
    ("OD01", "博報堂本社", "OD01-01", "企画部門", "OD01-01-A", "企画第一部"),
    ("OD02", "博報堂本社", "OD02-01", "制作部門", "OD02-01-A", "制作第一部"),
    ("OD03", "DYMPA", "OD03-01", "メディア部門", "OD03-01-A", "メディア企画部"),
    ("OD04", "大広本社", "OD04-01", "営業企画部門", "OD04-01-A", "営業企画部"),
    ("OD05", "読広本社", "OD05-01", "クリエイティブ部門", "OD05-01-A", "クリエイティブ部"),
]

# 制作媒体
PRODUCTION_DEPTS = [
    ("PM01", "博報堂プロダクツ", "PM01-01", "映像制作部門", "PM01-01-A", "映像制作部"),
    ("PM02", "博報堂プロダクツ", "PM02-01", "デジタル制作部門", "PM02-01-A", "デジタル制作部"),
    ("PM03", "アイ・スタジオ", "PM03-01", "Web制作部門", "PM03-01-A", "Web制作部"),
    ("PM04", "スパイスボックス", "PM04-01", "SNS運用部門", "PM04-01-A", "SNS運用部"),
]

# 得意先
CLIENTS = [
    ("C001", "トヨタ自動車株式会社"), ("C002", "本田技研工業株式会社"),
    ("C003", "日産自動車株式会社"), ("C004", "株式会社資生堂"),
    ("C005", "花王株式会社"), ("C006", "サントリーホールディングス株式会社"),
    ("C007", "キリンホールディングス株式会社"), ("C008", "味の素株式会社"),
    ("C009", "株式会社NTTドコモ"), ("C010", "KDDI株式会社"),
    ("C011", "ソフトバンク株式会社"), ("C012", "パナソニック株式会社"),
    ("C013", "ソニーグループ株式会社"), ("C014", "株式会社日立製作所"),
    ("C015", "三菱UFJフィナンシャル・グループ"), ("C016", "株式会社三井住友銀行"),
    ("C017", "第一生命保険株式会社"), ("C018", "日本生命保険相互会社"),
    ("C019", "株式会社リクルート"), ("C020", "楽天グループ株式会社"),
    ("C021", "株式会社ファーストリテイリング"), ("C022", "株式会社ニトリホールディングス"),
    ("C023", "アサヒグループホールディングス株式会社"), ("C024", "日清食品ホールディングス株式会社"),
    ("C025", "大塚ホールディングス株式会社"), ("C026", "武田薬品工業株式会社"),
    ("C027", "JTBグループ"), ("C028", "ANA ホールディングス株式会社"),
    ("C029", "株式会社セブン＆アイ・ホールディングス"), ("C030", "イオン株式会社"),
]

# 広告主（得意先と同一にするケースが多いが、広告主はブランド単位のことも）
ADVERTISERS = [
    ("A001", "トヨタ自動車", "IND01", "自動車・輸送機器", "IND01-01", "自動車", "IND01-01-01", "乗用車",
     "AG01", "トヨタグループ", "GI01", "自動車・輸送機器", "GI01-01", "自動車", "GI01-01-01", "乗用車"),
    ("A002", "レクサス", "IND01", "自動車・輸送機器", "IND01-01", "自動車", "IND01-01-02", "高級車",
     "AG01", "トヨタグループ", "GI01", "自動車・輸送機器", "GI01-01", "自動車", "GI01-01-01", "乗用車"),
    ("A003", "本田技研工業", "IND01", "自動車・輸送機器", "IND01-01", "自動車", "IND01-01-01", "乗用車",
     "AG02", "ホンダグループ", "GI01", "自動車・輸送機器", "GI01-01", "自動車", "GI01-01-01", "乗用車"),
    ("A004", "資生堂", "IND02", "化粧品・トイレタリー", "IND02-01", "化粧品", "IND02-01-01", "スキンケア",
     "AG03", "資生堂グループ", "GI02", "化粧品・トイレタリー", "GI02-01", "化粧品", "GI02-01-01", "スキンケア"),
    ("A005", "花王", "IND02", "化粧品・トイレタリー", "IND02-02", "トイレタリー", "IND02-02-01", "洗剤",
     "AG04", "花王グループ", "GI02", "化粧品・トイレタリー", "GI02-02", "トイレタリー", "GI02-02-01", "洗剤"),
    ("A006", "サントリー", "IND03", "食品・飲料", "IND03-01", "飲料", "IND03-01-01", "清涼飲料",
     "AG05", "サントリーグループ", "GI03", "食品・飲料", "GI03-01", "飲料", "GI03-01-01", "清涼飲料"),
    ("A007", "キリン", "IND03", "食品・飲料", "IND03-02", "酒類", "IND03-02-01", "ビール",
     "AG06", "キリングループ", "GI03", "食品・飲料", "GI03-02", "酒類", "GI03-02-01", "ビール"),
    ("A008", "味の素", "IND03", "食品・飲料", "IND03-03", "食品", "IND03-03-01", "調味料",
     "AG07", "味の素グループ", "GI03", "食品・飲料", "GI03-03", "食品", "GI03-03-01", "調味料"),
    ("A009", "NTTドコモ", "IND04", "情報・通信", "IND04-01", "通信", "IND04-01-01", "携帯電話",
     "AG08", "NTTグループ", "GI04", "情報・通信", "GI04-01", "通信", "GI04-01-01", "携帯電話"),
    ("A010", "KDDI", "IND04", "情報・通信", "IND04-01", "通信", "IND04-01-01", "携帯電話",
     "AG09", "KDDIグループ", "GI04", "情報・通信", "GI04-01", "通信", "GI04-01-01", "携帯電話"),
    ("A011", "ソフトバンク", "IND04", "情報・通信", "IND04-01", "通信", "IND04-01-02", "ブロードバンド",
     "AG10", "ソフトバンクグループ", "GI04", "情報・通信", "GI04-01", "通信", "GI04-01-01", "携帯電話"),
    ("A012", "パナソニック", "IND05", "電気機器", "IND05-01", "家電", "IND05-01-01", "生活家電",
     "AG11", "パナソニックグループ", "GI05", "電気機器", "GI05-01", "家電", "GI05-01-01", "生活家電"),
    ("A013", "ソニー", "IND05", "電気機器", "IND05-02", "エンタテインメント", "IND05-02-01", "ゲーム",
     "AG12", "ソニーグループ", "GI05", "電気機器", "GI05-02", "エンタテインメント", "GI05-02-01", "ゲーム"),
    ("A014", "三菱UFJ", "IND06", "金融・保険", "IND06-01", "銀行", "IND06-01-01", "都市銀行",
     "AG13", "MUFGグループ", "GI06", "金融・保険", "GI06-01", "銀行", "GI06-01-01", "都市銀行"),
    ("A015", "リクルート", "IND07", "サービス", "IND07-01", "人材", "IND07-01-01", "求人",
     "AG14", "リクルートグループ", "GI07", "サービス", "GI07-01", "人材", "GI07-01-01", "求人"),
    ("A016", "楽天", "IND04", "情報・通信", "IND04-02", "IT", "IND04-02-01", "EC",
     "AG15", "楽天グループ", "GI04", "情報・通信", "GI04-02", "IT", "GI04-02-01", "EC"),
    ("A017", "ファーストリテイリング", "IND08", "流通・小売", "IND08-01", "アパレル", "IND08-01-01", "カジュアル",
     "AG16", "ファーストリテイリンググループ", "GI08", "流通・小売", "GI08-01", "アパレル", "GI08-01-01", "カジュアル"),
    ("A018", "日清食品", "IND03", "食品・飲料", "IND03-03", "食品", "IND03-03-02", "即席麺",
     "AG17", "日清食品グループ", "GI03", "食品・飲料", "GI03-03", "食品", "GI03-03-02", "即席麺"),
    ("A019", "ANA", "IND09", "運輸・レジャー", "IND09-01", "航空", "IND09-01-01", "旅客",
     "AG18", "ANAグループ", "GI09", "運輸・レジャー", "GI09-01", "航空", "GI09-01-01", "旅客"),
    ("A020", "セブン＆アイ", "IND08", "流通・小売", "IND08-02", "コンビニ", "IND08-02-01", "コンビニエンスストア",
     "AG19", "セブン＆アイグループ", "GI08", "流通・小売", "GI08-02", "コンビニ", "GI08-02-01", "コンビニエンスストア"),
]

# 支払先
PAYEES = [
    ("P001", "株式会社電通"), ("P002", "株式会社TBSテレビ"),
    ("P003", "日本テレビ放送網株式会社"), ("P004", "株式会社フジテレビジョン"),
    ("P005", "株式会社テレビ朝日"), ("P006", "株式会社テレビ東京"),
    ("P007", "株式会社朝日新聞社"), ("P008", "株式会社読売新聞社"),
    ("P009", "株式会社日本経済新聞社"), ("P010", "株式会社毎日新聞社"),
    ("P011", "Google合同会社"), ("P012", "Meta日本株式会社"),
    ("P013", "ヤフー株式会社"), ("P014", "Twitter Japan株式会社"),
    ("P015", "LINE株式会社"), ("P016", "株式会社JR東日本企画"),
    ("P017", "株式会社東急エージェンシー"), ("P018", "株式会社サイバーエージェント"),
    ("P019", "株式会社集英社"), ("P020", "株式会社講談社"),
]

# マスメディア区分
MASS_MEDIA = [
    ("M01", "テレビ"), ("M02", "新聞"), ("M03", "雑誌"),
    ("M04", "ラジオ"), ("M05", "デジタル"), ("M06", "OOH（屋外）"),
]

# 媒体社
MEDIA_COMPANIES = [
    ("MC01", "TBSテレビ"), ("MC02", "日本テレビ"), ("MC03", "フジテレビ"),
    ("MC04", "テレビ朝日"), ("MC05", "テレビ東京"), ("MC06", "NHK"),
    ("MC07", "朝日新聞"), ("MC08", "読売新聞"), ("MC09", "日経新聞"),
    ("MC10", "Google"), ("MC11", "Yahoo!"), ("MC12", "Meta"),
    ("MC13", "LINE"), ("MC14", "JR東日本企画"), ("MC15", "集英社"),
]

# 売上種目
SALES_CATEGORIES = [
    ("SC01", "テレビスポット"), ("SC02", "テレビタイム"), ("SC03", "新聞広告"),
    ("SC04", "雑誌広告"), ("SC05", "ラジオスポット"), ("SC06", "デジタル広告"),
    ("SC07", "動画広告"), ("SC08", "SNS広告"), ("SC09", "交通広告"),
    ("SC10", "屋外広告"),
]

# 媒体種目
MEDIA_CATEGORIES = [
    ("MT01", "スポットCM"), ("MT02", "タイムCM"), ("MT03", "全国紙"),
    ("MT04", "月刊誌"), ("MT05", "FMスポット"), ("MT06", "リスティング"),
    ("MT07", "ディスプレイ"), ("MT08", "動画配信"), ("MT09", "駅構内"),
    ("MT10", "ビルボード"),
]

# 媒体種類
MEDIA_TYPES = [
    ("MK01", "地上波テレビ"), ("MK02", "BS・CS"), ("MK03", "全国紙朝刊"),
    ("MK04", "全国紙夕刊"), ("MK05", "週刊誌"), ("MK06", "月刊誌"),
    ("MK07", "FM放送"), ("MK08", "AM放送"), ("MK09", "検索連動型"),
    ("MK10", "ディスプレイ広告"), ("MK11", "SNSフィード"), ("MK12", "インストリーム動画"),
    ("MK13", "駅看板"), ("MK14", "電車内広告"), ("MK15", "デジタルサイネージ"),
]

# ビークル
VEHICLES = [
    ("V001", "TBS系全国ネット"), ("V002", "日テレ系全国ネット"),
    ("V003", "フジ系全国ネット"), ("V004", "テレ朝系全国ネット"),
    ("V005", "朝日新聞朝刊全国版"), ("V006", "読売新聞朝刊全国版"),
    ("V007", "日経新聞朝刊"), ("V008", "Google検索広告"),
    ("V009", "YouTube広告"), ("V010", "Facebook/Instagram広告"),
    ("V011", "LINE広告"), ("V012", "Yahoo!ディスプレイ"),
    ("V013", "JR首都圏主要駅"), ("V014", "東京メトロ車内"),
    ("V015", "渋谷大型ビジョン"),
]

# 年月の生成（2023年4月〜2025年3月 = 24ヶ月）
YEAR_MONTHS = []
for y in [2023, 2024]:
    for m in range(4, 13):
        YEAR_MONTHS.append((y if m >= 4 else y, y * 100 + m))
    for m in range(1, 4):
        YEAR_MONTHS.append((y if m >= 4 else y, (y + 1) * 100 + m))

# Fix: proper fiscal year + year_month
YEAR_MONTHS = []
for fy in [2023, 2024]:
    for m in range(4, 13):
        YEAR_MONTHS.append((fy, fy * 100 + m))
    for m in range(1, 4):
        YEAR_MONTHS.append((fy, (fy + 1) * 100 + m))


def get_quarter(month):
    if month in [4, 5, 6]:
        return "1Q"
    elif month in [7, 8, 9]:
        return "2Q"
    elif month in [10, 11, 12]:
        return "3Q"
    else:
        return "4Q"


def get_rb_date(ym):
    """年月から適当なRB処理日を生成"""
    y = ym // 100
    m = ym % 100
    d = random.randint(1, 28)
    return y * 10000 + m * 100 + d


# ============================================================
# 1. PURCHASE_NEW_TABLE 生成（10,000行、4ファイル）
# ============================================================
def generate_purchase_data():
    print("Generating PURCHASE_NEW_TABLE data...")
    headers = [
        "RB処理日", "年度_4月起点", "年月", "四半期_4月起点",
        "会社_営業_コード_最新", "会社_営業_名_最新",
        "営業部門コード_最新", "営業部門名_最新",
        "営業部署コード_最新", "営業部署名_最新",
        "会社_G発注元コード_最新", "会社_G発注元名_最新",
        "G発注元部門コード_最新", "G発注元部門名_最新",
        "G発注元部署コード_最新", "G発注元部署名_最新",
        "会社_制作媒体コード_最新", "会社_制作媒体名_最新",
        "制作媒体部門コード_最新", "制作媒体部門名_最新",
        "制作媒体部署コード_最新", "制作媒体部署名_最新",
        "得意先コード", "得意先名",
        "広告主コード", "広告主名",
        "広告主業種_大コード", "広告主業種_大名",
        "広告主業種_中コード", "広告主業種_中名",
        "広告主業種_小コード", "広告主業種_小名",
        "広告主企業グループコード", "広告主企業グループ名",
        "広告主企業グループ業種_大コード", "広告主企業グループ業種_大名",
        "広告主企業グループ業種_中コード", "広告主企業グループ業種_中名",
        "広告主企業グループ業種_小コード", "広告主企業グループ業種_小名",
        "支払先コード", "支払先名",
        "マスメディア区分", "マスメディア区分名",
        "実施媒体社コード", "実施媒体社名",
        "売上種目コード", "売上種目名",
        "媒体種目コード", "媒体種目名",
        "媒体種類コード", "媒体種類名",
        "ビークルコード", "ビークル名",
        "仕入高予算", "仕入高_建値",
        "媒体戦略原価B予算", "媒体戦略原価B_正味",
        "媒体収益予算", "媒体収益実績_正味",
        "FC営収予算_社内_社外", "FC営収_社内_社外",
        "スタッフコスト",
    ]

    rows = []
    for i in range(10000):
        fy, ym = random.choice(YEAR_MONTHS)
        month = ym % 100
        quarter = get_quarter(month)
        agency = random.choice(AGENCIES)
        sales = random.choice(SALES_DEPTS)
        ordering = random.choice(ORDERING_DEPTS)
        production = random.choice(PRODUCTION_DEPTS)
        client = random.choice(CLIENTS)
        adv = random.choice(ADVERTISERS)
        payee = random.choice(PAYEES)
        media = random.choice(MASS_MEDIA)
        media_co = random.choice(MEDIA_COMPANIES)
        sales_cat = random.choice(SALES_CATEGORIES)
        media_cat = random.choice(MEDIA_CATEGORIES)
        media_type = random.choice(MEDIA_TYPES)
        vehicle = random.choice(VEHICLES)

        # 金額はリアリティのある範囲で
        purchase_budget = random.randint(100000, 50000000)
        purchase_actual = int(purchase_budget * random.uniform(0.7, 1.3))
        media_cost_budget = int(purchase_budget * random.uniform(0.5, 0.8))
        media_cost_actual = int(media_cost_budget * random.uniform(0.7, 1.2))
        media_rev_budget = int(purchase_budget * random.uniform(0.1, 0.3))
        media_rev_actual = int(media_rev_budget * random.uniform(0.6, 1.4))
        fc_budget = int(purchase_budget * random.uniform(0.05, 0.15))
        fc_actual = int(fc_budget * random.uniform(0.7, 1.3))
        staff_cost = int(purchase_budget * random.uniform(0.02, 0.08))

        row = [
            get_rb_date(ym), fy, ym, quarter,
            agency[0], agency[1],
            sales[0], sales[1], sales[2], sales[3],
            ordering[0], ordering[1], ordering[2], ordering[3], ordering[4], ordering[5],
            production[0], production[1], production[2], production[3], production[4], production[5],
            client[0], client[1],
            adv[0], adv[1], adv[2], adv[3], adv[4], adv[5], adv[6], adv[7],
            adv[8], adv[9], adv[10], adv[11], adv[12], adv[13], adv[14], adv[15],
            payee[0], payee[1],
            media[0], media[1],
            media_co[0], media_co[1],
            sales_cat[0], sales_cat[1],
            media_cat[0], media_cat[1],
            media_type[0], media_type[1],
            vehicle[0], vehicle[1],
            purchase_budget, purchase_actual,
            media_cost_budget, media_cost_actual,
            media_rev_budget, media_rev_actual,
            fc_budget, fc_actual,
            staff_cost,
        ]
        rows.append(row)

    # 4ファイルに分割
    chunk_size = 2500
    out_dir = os.path.join(BASE_DIR, "purchase_new_table")
    for idx in range(4):
        chunk = rows[idx * chunk_size:(idx + 1) * chunk_size]
        filepath = os.path.join(out_dir, f"purchase_part_{idx + 1:03d}.csv")
        with open(filepath, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(headers)
            writer.writerows(chunk)
        print(f"  Written {filepath} ({len(chunk)} rows)")


# ============================================================
# 2. SPECIAL_FEE_TABLE 生成（10,000行、4ファイル）
# ============================================================
def generate_special_fee_data():
    print("Generating SPECIAL_FEE_TABLE data...")
    headers = [
        "RB処理日", "会社", "部門G", "部門", "部署",
        "年度", "年月", "四半期",
        "管理項目コード", "管理項目名称",
        "補助項目コード", "補助項目名称",
        "実績", "予算",
    ]

    companies = ["博報堂", "博報堂DYメディアパートナーズ", "大広", "読売広告社", "博報堂プロダクツ"]
    dept_groups = ["営業統括", "メディア統括", "クリエイティブ統括", "デジタル統括", "管理統括"]
    departments = [
        "第一営業部", "第二営業部", "メディアプランニング部", "デジタルマーケティング部",
        "クリエイティブ部", "制作部", "経営企画部", "人事部", "財務経理部", "総務部",
    ]
    sections = [
        "第一課", "第二課", "第三課", "企画課", "推進課",
        "管理課", "開発課", "運用課",
    ]
    mgmt_items = [
        (100001, "売上高"), (100002, "売上原価"), (100003, "売上総利益"),
        (200001, "人件費"), (200002, "経費"), (200003, "減価償却費"),
        (300001, "営業利益"), (300002, "経常利益"),
        (400001, "媒体手数料収入"), (400002, "制作収入"), (400003, "コンサルティング収入"),
        (500001, "広告主負担金"), (500002, "媒体社リベート"),
    ]
    sub_items = [
        ("S001", "通常"), ("S002", "特別"), ("S003", "調整"),
        ("S004", "見込"), ("S005", "確定"),
    ]

    rows = []
    for i in range(10000):
        fy, ym = random.choice(YEAR_MONTHS)
        month = ym % 100
        quarter = get_quarter(month)
        company = random.choice(companies)
        dept_g = random.choice(dept_groups)
        dept = random.choice(departments)
        section = random.choice(sections)
        item = random.choice(mgmt_items)
        sub = random.choice(sub_items)

        budget = random.randint(1000000, 500000000)
        actual = int(budget * random.uniform(0.6, 1.4))

        row = [
            get_rb_date(ym), company, dept_g, dept, section,
            fy, ym, quarter,
            item[0], item[1],
            sub[0], sub[1],
            actual, budget,
        ]
        rows.append(row)

    # 4ファイルに分割
    chunk_size = 2500
    out_dir = os.path.join(BASE_DIR, "special_fee_table")
    for idx in range(4):
        chunk = rows[idx * chunk_size:(idx + 1) * chunk_size]
        filepath = os.path.join(out_dir, f"special_fee_part_{idx + 1:03d}.csv")
        with open(filepath, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(headers)
            writer.writerows(chunk)
        print(f"  Written {filepath} ({len(chunk)} rows)")


# ============================================================
# 3. MST_AGENCY_GROUP 生成（30行、2ファイル）
# ============================================================
def generate_agency_master():
    print("Generating MST_AGENCY_GROUP data...")
    headers = ["AGENCY_CODE_LATEST", "AGENCY_NAME_LATEST", "AGENCY_KEY"]

    # 2ファイルに分割
    mid = len(AGENCIES) // 2
    parts = [AGENCIES[:mid], AGENCIES[mid:]]

    out_dir = os.path.join(BASE_DIR, "mst_agency_group")
    for idx, part in enumerate(parts):
        filepath = os.path.join(out_dir, f"mst_agency_part_{idx + 1:03d}.csv")
        with open(filepath, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(headers)
            for a in part:
                writer.writerow([a[0], a[1], a[2]])
        print(f"  Written {filepath} ({len(part)} rows)")


# ============================================================
# Main
# ============================================================
if __name__ == "__main__":
    generate_purchase_data()
    generate_special_fee_data()
    generate_agency_master()
    print("\nDone! All CSV files generated.")
