# AI Social App - MVP

AI社交角色App最小可用版本。

## 功能

- AI聊天 - 与多个角色对话
- 角色列表 - 选择不同角色
- AI API切换 - 支持DeepSeek/Qwen/OpenAI/自定义
- 本地存储 - SQLite保存聊天记录

## 快速开始

### 前置要求

- Flutter SDK >= 3.0
- Android Studio 或 VS Code

### 运行

```bash
cd frontend
flutter pub get
flutter run
```

### 配置

1. 打开App → 右上角设置按钮
2. 选择AI提供商（DeepSeek/Qwen/OpenAI/自定义）
3. 输入API Key
4. 点击保存设置
5. 返回首页选择角色开始聊天

### 可选 - 运行后端

```bash
cd backend
pip install fastapi uvicorn httpx
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## 技术栈

| 模块 | 技术 |
|------|------|
| 前端 | Flutter |
| 本地存储 | SQLite (sqflite) |
| AI接口 | OpenAI-compatible API |
| 后端(可选) | Python FastAPI |

## 项目结构

```
ai_social_app/
├── frontend/
│   └── lib/
│       ├── main.dart              # 入口
│       ├── app.dart               # 应用配置
│       ├── pages/
│       │   ├── home_page.dart     # 角色列表
│       │   ├── chat_page.dart     # 聊天页面
│       │   └── settings_page.dart # API设置
│       └── services/
│           ├── api_service.dart         # AI API调用
│           ├── ai_provider.dart         # AI提供商定义
│           └── database_service.dart    # SQLite数据库
├── backend/
│   ├── main.py                   # FastAPI入口
│   └── ai_router.py              # AI路由(可选)
├── .github/workflows/
│   └── build.yml                 # CI/CD配置
├── pubspec.yaml
└── README.md
```

## API配置示例

| 提供商 | Base URL | 推荐Model |
|---------|----------|-----------|
| DeepSeek | https://api.deepseek.com | deepseek-chat |
| 通义千问 | https://dashscope.aliyuncs.com/compatible-mode/v1 | qwen-plus |
| OpenAI | https://api.openai.com/v1 | gpt-3.5-turbo |
| 自定义 | 你的API地址 | 你的模型名 |

## 数据库表结构

**messages表**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键自增 |
| role | TEXT | user 或 ai |
| content | TEXT | 消息内容 |
| roleName | TEXT | 角色名称 |
| timestamp | TEXT | 时间戳 |

**settings表**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键自增 |
| apiKey | TEXT | API密钥 |
| baseUrl | TEXT | API地址 |
| model | TEXT | 模型名 |
| provider | TEXT | 提供商标识 |

## 后续升级路线

- [ ] 朋友圈系统
- [ ] 主动消息推送
- [ ] AI角色人格系统
- [ ] 情绪系统
- [ ] 剧情系统
