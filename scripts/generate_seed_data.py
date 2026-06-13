#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GameRec 种子数据生成脚本

生成：
1. games.json - 100+款游戏库
2. user_library.json - 测试用户的已玩游戏记录
3. prices.json - 游戏价格表

使用方法：
python generate_seed_data.py
"""

import json
import random
from datetime import datetime, timedelta
from typing import List, Dict, Any

# ==================== 配置区 ====================

OUTPUT_DIR = "../GameRec/Resources/Data/SeedData"
NUM_GAMES = 120  # 生成的游戏数量
NUM_USER_PLAYED = 35  # 用户已玩的游戏数量

# 平台列表
PLATFORMS = ["PSN", "Steam", "Switch"]

# 游戏类别（对应 GameCategory.swift）
CATEGORIES = [
    "RPG", "动作RPG", "Roguelike", "Roguelite", "银河恶魔城",
    "射击", "第一人称射击", "第三人称射击", "动作", "冒险",
    "解谜", "平台跳跃", "格斗", "赛车", "体育",
    "模拟", "策略", "MOBA", "MMO", "沙盒",
    "生存", "恐怖", "潜行", "音乐节奏", "Galgame",
    "卡牌", "独立游戏", "开放世界", "魂系"
]

# 合法类别集合（必须与 GameCategory.swift 的 rawValue 完全一致）
# 用于过滤掉枚举中不存在的类别，避免 Swift 解码失败
VALID_CATEGORIES = set(CATEGORIES)

# 非法类别 → 合法类别的映射（脚本里曾用到枚举外的值）
CATEGORY_FALLBACK = {
    "回合制": "策略",
    "即时战略": "策略",
    "科幻": "射击",
}


def sanitize_categories(categories):
    """把类别规整为枚举内的合法值：能映射的映射，不能映射的丢弃，去重保序，空则兜底为独立游戏"""
    result = []
    for c in categories:
        if c in VALID_CATEGORIES:
            mapped = c
        elif c in CATEGORY_FALLBACK:
            mapped = CATEGORY_FALLBACK[c]
        else:
            continue
        if mapped not in result:
            result.append(mapped)
    if not result:
        result.append("独立游戏")
    return result

# ==================== 游戏数据库 ====================

# 真实游戏数据（部分）+ 虚构游戏
GAME_DATABASE = [
    # 动作RPG / 魂系
    {
        "title": "艾尔登法环",
        "categories": ["动作RPG", "开放世界", "魂系"],
        "tags": ["开放世界", "魂系", "困难", "探索", "BOSS战", "FromSoftware"],
        "description": "FromSoftware与《冰与火之歌》作者合作的开放世界魂系游戏",
        "year": 2022,
        "platforms": ["PSN", "Steam"],
        "base_price": 298
    },
    {
        "title": "只狼：影逝二度",
        "categories": ["动作", "魂系"],
        "tags": ["魂系", "困难", "日本战国", "弹反", "FromSoftware"],
        "description": "FromSoftware的战国主题硬核动作游戏",
        "year": 2019,
        "platforms": ["PSN", "Steam"],
        "base_price": 268
    },
    {
        "title": "黑暗之魂3",
        "categories": ["动作RPG", "魂系"],
        "tags": ["魂系", "困难", "黑暗奇幻", "BOSS战", "FromSoftware"],
        "description": "魂系列的集大成之作",
        "year": 2016,
        "platforms": ["PSN", "Steam"],
        "base_price": 198
    },
    
    # RPG
    {
        "title": "女神异闻录5 皇家版",
        "categories": ["RPG", "Galgame"],
        "tags": ["回合制", "剧情向", "学园", "日式RPG", "音乐优秀"],
        "description": "ATLUS经典JRPG系列的集大成之作",
        "year": 2019,
        "platforms": ["PSN", "Steam", "Switch"],
        "base_price": 398
    },
    {
        "title": "最终幻想7 重制版",
        "categories": ["动作RPG"],
        "tags": ["剧情向", "画面优秀", "日式RPG", "经典重制"],
        "description": "经典RPG的现代化重制",
        "year": 2020,
        "platforms": ["PSN", "Steam"],
        "base_price": 458
    },
    {
        "title": "尼尔：机械纪元",
        "categories": ["动作RPG"],
        "tags": ["剧情神", "音乐优秀", "横尾太郎", "哲学", "多周目"],
        "description": "横尾太郎的哲学动作RPG",
        "year": 2017,
        "platforms": ["PSN", "Steam"],
        "base_price": 199
    },
    {
        "title": "巫师3：狂猎",
        "categories": ["动作RPG", "开放世界"],
        "tags": ["开放世界", "剧情向", "选择分支", "中世纪奇幻"],
        "description": "史诗级开放世界RPG",
        "year": 2015,
        "platforms": ["PSN", "Steam", "Switch"],
        "base_price": 127
    },
    
    # Roguelike/Roguelite
    {
        "title": "哈迪斯",
        "categories": ["Roguelite", "动作"],
        "tags": ["Roguelite", "希腊神话", "剧情向", "重复可玩性高"],
        "description": "SuperGiant的Roguelite神作",
        "year": 2020,
        "platforms": ["PSN", "Steam", "Switch"],
        "base_price": 90
    },
    {
        "title": "死亡细胞",
        "categories": ["Roguelite", "银河恶魔城"],
        "tags": ["Roguelite", "横版", "快节奏", "高难度"],
        "description": "类银河恶魔城Roguelite",
        "year": 2018,
        "platforms": ["PSN", "Steam", "Switch"],
        "base_price": 90
    },
    {
        "title": "以撒的结合：忏悔",
        "categories": ["Roguelike"],
        "tags": ["Roguelike", "暗黑", "重复可玩性高", "地牢探索"],
        "description": "经典Roguelike代表作",
        "year": 2021,
        "platforms": ["Steam", "Switch"],
        "base_price": 128
    },
    
    # 银河恶魔城
    {
        "title": "空洞骑士",
        "categories": ["银河恶魔城", "独立游戏"],
        "tags": ["银河恶魔城", "横版", "探索", "美术优秀", "BOSS战"],
        "description": "独立游戏的银河恶魔城巅峰之作",
        "year": 2017,
        "platforms": ["PSN", "Steam", "Switch"],
        "base_price": 48
    },
    {
        "title": "奥日与黑暗森林",
        "categories": ["银河恶魔城", "平台跳跃"],
        "tags": ["银河恶魔城", "画面优秀", "音乐优秀", "解谜"],
        "description": "画面精美的银河恶魔城",
        "year": 2015,
        "platforms": ["Steam"],
        "base_price": 68
    },
    
    # 射击类
    {
        "title": "DOOM 永恒",
        "categories": ["第一人称射击", "动作"],
        "tags": ["快节奏", "爽快", "恶魔", "重金属"],
        "description": "极速射击体验",
        "year": 2020,
        "platforms": ["PSN", "Steam", "Switch"],
        "base_price": 299
    },
    {
        "title": "无主之地3",
        "categories": ["第一人称射击", "RPG"],
        "tags": ["刷装备", "合作", "幽默", "开放世界"],
        "description": "刷刷刷射击游戏",
        "year": 2019,
        "platforms": ["PSN", "Steam"],
        "base_price": 199
    },
    
    # 恐怖类
    {
        "title": "生化危机2 重制版",
        "categories": ["恐怖", "第三人称射击"],
        "tags": ["恐怖", "生存", "经典重制", "僵尸"],
        "description": "恐怖游戏经典重制",
        "year": 2019,
        "platforms": ["PSN", "Steam"],
        "base_price": 199
    },
    {
        "title": "寂静岭2",
        "categories": ["恐怖", "冒险"],
        "tags": ["恐怖", "心理", "剧情神", "经典"],
        "description": "心理恐怖巅峰之作",
        "year": 2001,
        "platforms": ["PSN"],
        "base_price": 0
    },
    
    # 独立游戏
    {
        "title": "星露谷物语",
        "categories": ["模拟", "独立游戏"],
        "tags": ["农场", "养成", "休闲", "治愈"],
        "description": "治愈系农场模拟",
        "year": 2016,
        "platforms": ["PSN", "Steam", "Switch"],
        "base_price": 68
    },
    {
        "title": "泰拉瑞亚",
        "categories": ["沙盒", "独立游戏"],
        "tags": ["沙盒", "建造", "探索", "BOSS战"],
        "description": "2D沙盒探索",
        "year": 2011,
        "platforms": ["PSN", "Steam", "Switch"],
        "base_price": 40
    },
    
    # Galgame
    {
        "title": "命运石之门",
        "categories": ["Galgame", "冒险"],
        "tags": ["剧情神", "时间旅行", "科幻", "视觉小说"],
        "description": "科幻题材神作视觉小说",
        "year": 2009,
        "platforms": ["PSN", "Steam", "Switch"],
        "base_price": 98
    },
    {
        "title": "白色相簿2",
        "categories": ["Galgame"],
        "tags": ["剧情向", "恋爱", "音乐", "催泪"],
        "description": "经典恋爱AVG",
        "year": 2010,
        "platforms": ["Steam"],
        "base_price": 88
    },
    
    # 策略类
    {
        "title": "文明6",
        "categories": ["策略", "回合制"],
        "tags": ["4X", "回合制", "历史", "策略"],
        "description": "经典回合制策略",
        "year": 2016,
        "platforms": ["PSN", "Steam", "Switch"],
        "base_price": 199
    },
    {
        "title": "全面战争：三国",
        "categories": ["策略", "即时战略"],
        "tags": ["即时战略", "历史", "三国", "战争"],
        "description": "三国题材即时战略",
        "year": 2019,
        "platforms": ["Steam"],
        "base_price": 268
    },
]

# 补充虚构游戏数据（用于扩充到120款）
FICTIONAL_GAMES = [
    {"title": "幻想编年史", "categories": ["RPG"], "tags": ["剧情向", "回合制", "奇幻"]},
    {"title": "暗影行者", "categories": ["动作", "潜行"], "tags": ["潜行", "暗杀", "忍者"]},
    {"title": "星际征途", "categories": ["射击", "科幻"], "tags": ["太空", "射击", "科幻"]},
    {"title": "迷雾之森", "categories": ["冒险", "解谜"], "tags": ["解谜", "探索", "神秘"]},
    {"title": "赛博都市", "categories": ["动作RPG", "开放世界"], "tags": ["赛博朋克", "开放世界", "科幻"]},
    {"title": "机械纪元2077", "categories": ["动作", "射击"], "tags": ["机甲", "未来", "科幻"]},
    {"title": "龙之遗产", "categories": ["RPG", "动作"], "tags": ["龙", "奇幻", "探索"]},
    {"title": "地下城传说", "categories": ["Roguelike", "RPG"], "tags": ["地牢", "随机", "刷宝"]},
    {"title": "光影旅者", "categories": ["冒险", "独立游戏"], "tags": ["艺术", "解谜", "唯美"]},
    {"title": "魔法学院", "categories": ["RPG", "模拟"], "tags": ["魔法", "学园", "养成"]},
]

# ==================== 生成函数 ====================

def generate_game_id(index: int) -> str:
    """生成游戏ID"""
    return f"game_{str(index).zfill(3)}"


def generate_games() -> List[Dict[str, Any]]:
    """生成游戏库JSON"""
    games = []
    
    # 先添加真实游戏
    for i, game_data in enumerate(GAME_DATABASE):
        game = {
            "id": generate_game_id(i + 1),
            "title": game_data["title"],
            "categories": sanitize_categories(game_data["categories"]),
            "tags": game_data["tags"],
            "description": game_data.get("description", f"{game_data['title']}的游戏描述"),
            "releaseYear": game_data.get("year", random.randint(2015, 2024)),
            "platforms": game_data["platforms"],
            "imageURL": None
        }
        games.append(game)
    
    # 补充虚构游戏到目标数量
    start_index = len(GAME_DATABASE) + 1
    remaining = NUM_GAMES - len(GAME_DATABASE)
    
    for i in range(remaining):
        # 循环使用虚构游戏模板
        template = FICTIONAL_GAMES[i % len(FICTIONAL_GAMES)]
        
        game = {
            "id": generate_game_id(start_index + i),
            "title": f"{template['title']} {i // len(FICTIONAL_GAMES) + 1}" if i >= len(FICTIONAL_GAMES) else template["title"],
            "categories": sanitize_categories(template["categories"]),
            "tags": template.get("tags", ["探索", "冒险"]),
            "description": f"这是一款{template['categories'][0]}类型的游戏",
            "releaseYear": random.randint(2015, 2024),
            "platforms": random.sample(PLATFORMS, k=random.randint(1, 3)),
            "imageURL": None
        }
        games.append(game)
    
    return games


def generate_prices(games: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """生成价格表JSON"""
    prices = []
    
    for game in games:
        # 从GAME_DATABASE获取base_price，否则随机
        base_price = None
        for db_game in GAME_DATABASE:
            if db_game["title"] == game["title"]:
                base_price = db_game.get("base_price", random.randint(40, 400))
                break
        
        if base_price is None:
            base_price = random.choice([0, 40, 68, 90, 128, 198, 268, 298, 398])
        
        # 为每个平台生成价格
        for platform in game["platforms"]:
            # 是否打折（30%概率）
            is_on_sale = random.random() < 0.3
            discount = random.choice([20, 30, 40, 50, 60]) if is_on_sale else 0
            current_price = base_price * (1 - discount / 100.0) if base_price > 0 else 0
            
            price_record = {
                "id": f"{game['id']}_{platform}",
                "gameId": game["id"],
                "platform": platform,
                "originalPrice": base_price,
                "currentPrice": round(current_price, 2),
                "discountPercentage": discount,
                "isFree": base_price == 0,
                "lastUpdated": datetime.now().isoformat()
            }
            prices.append(price_record)
    
    return prices


def generate_user_library(games: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """生成用户游戏库JSON"""
    user_library = []
    
    # 随机选择用户已玩的游戏
    played_games = random.sample(games, min(NUM_USER_PLAYED, len(games)))
    
    for game in played_games:
        # 随机选择一个平台（从游戏支持的平台中）
        platform = random.choice(game["platforms"])
        
        # 生成游戏数据
        hours_played = random.uniform(5, 150)
        progress = random.randint(10, 100)
        total_achievements = random.randint(20, 80)
        unlocked = int(total_achievements * (progress / 100.0) * random.uniform(0.7, 1.0))
        
        # 最后游玩时间（最近3个月内）
        days_ago = random.randint(1, 90)
        last_played = (datetime.now() - timedelta(days=days_ago)).isoformat()
        
        record = {
            "id": f"{game['id']}_{platform}",
            "gameId": game["id"],
            "platform": platform,
            "hoursPlayed": round(hours_played, 1),
            "progressPercentage": progress,
            "achievementsUnlocked": unlocked,
            "totalAchievements": total_achievements,
            "lastPlayedDate": last_played
        }
        user_library.append(record)
    
    return user_library


def save_json(data: Any, filename: str):
    """保存JSON文件"""
    import os
    
    # 确保输出目录存在
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    filepath = os.path.join(OUTPUT_DIR, filename)
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"✅ 已生成: {filepath} ({len(data) if isinstance(data, list) else 1}条记录)")


# ==================== 主函数 ====================

def main():
    print("🎮 GameRec 种子数据生成器")
    print("=" * 50)
    
    # 设置随机种子（可复现）
    random.seed(42)
    
    # 1. 生成游戏库
    print("\n📦 生成游戏库...")
    games = generate_games()
    save_json(games, "games.json")
    
    # 2. 生成价格表
    print("\n💰 生成价格表...")
    prices = generate_prices(games)
    save_json(prices, "prices.json")
    
    # 3. 生成用户游戏库
    print("\n👤 生成用户游戏库...")
    user_library = generate_user_library(games)
    save_json(user_library, "user_library.json")
    
    print("\n" + "=" * 50)
    print("✨ 所有数据生成完成！")
    print(f"📊 统计:")
    print(f"  - 游戏总数: {len(games)}")
    print(f"  - 价格记录: {len(prices)}")
    print(f"  - 用户已玩: {len(user_library)}")
    
    # 显示一些示例
    print(f"\n🎯 示例游戏:")
    for game in games[:3]:
        print(f"  - {game['title']} ({', '.join(game['categories'])})")


if __name__ == "__main__":
    main()


