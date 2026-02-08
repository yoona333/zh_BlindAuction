# Git 子模块完全指南

> 本文档教你如何管理 BlindAuction 项目的 Git 子模块

## 📋 项目结构

```
BlindAuction (主仓库)
├── fhevm-hardhat-template/   # 子模块：智能合约
├── zh-blindauction/          # 子模块：前端应用
├── scripts/                  # 工具脚本
├── CLAUDE.md                 # AI 助手指南
└── ...其他文件
```

## 🎯 什么是 Git 子模块？

**子模块** 允许你在一个 Git 仓库中引用另一个 Git 仓库，同时保持它们的独立性。

**优点**：
- ✅ 每个模块独立开发和版本控制
- ✅ 主仓库只记录子模块的特定版本
- ✅ 团队成员可以独立更新各自负责的模块

---

## 🚀 初次配置子模块

### 1. 配置 fhevm-hardhat-template 和 zh-blindauction 为子模块

```bash
# 进入项目根目录
cd d:\zh-projects\BlindAuction

# 从主仓库的 Git 索引中移除这两个目录（但保留文件）
git rm --cached -r fhevm-hardhat-template zh-blindauction

# 添加为正式的 Git 子模块
git submodule add https://github.com/zama-ai/fhevm-hardhat-template.git fhevm-hardhat-template
git submodule add https://github.com/yoona333/zh-blindauction.git zh-blindauction

# 提交更改
git add .gitmodules .gitignore fhevm-hardhat-template zh-blindauction
git commit -m "chore: 配置 Git 子模块"

# 推送到 GitHub
git push origin main
```

### 2. 验证子模块配置

```bash
# 查看子模块状态
git submodule status

# 查看 .gitmodules 文件
cat .gitmodules
```

你会看到类似这样的输出：
```
[submodule "fhevm-hardhat-template"]
    path = fhevm-hardhat-template
    url = https://github.com/zama-ai/fhevm-hardhat-template.git
[submodule "zh-blindauction"]
    path = zh-blindauction
    url = https://github.com/yoona333/zh-blindauction.git
```

---

## 📚 日常操作

### 克隆包含子模块的项目（新电脑/新成员）

```bash
# 方法 1: 克隆时同时初始化子模块（推荐）
git clone --recurse-submodules https://github.com/yoona333/zh_BlindAuction.git

# 方法 2: 先克隆主仓库，再初始化子模块
git clone https://github.com/yoona333/zh_BlindAuction.git
cd zh_BlindAuction
git submodule update --init --recursive
```

### 更新子模块到最新版本

#### 更新单个子模块

```bash
# 进入子模块目录
cd zh-blindauction

# 拉取最新代码
git pull origin main

# 返回主仓库
cd ..

# 提交子模块的版本更新
git add zh-blindauction
git commit -m "chore: 更新 zh-blindauction 子模块"
git push
```

#### 更新所有子模块

```bash
# 在主仓库根目录执行
git submodule update --remote --merge

# 提交更新
git add .
git commit -m "chore: 更新所有子模块到最新版本"
git push
```

### 在子模块中进行开发

#### 修改前端代码（zh-blindauction）

```bash
# 1. 进入子模块
cd zh-blindauction

# 2. 确保在正确的分支
git checkout main

# 3. 拉取最新代码
git pull

# 4. 进行修改...（编辑文件）

# 5. 提交到子模块仓库
git add .
git commit -m "feat: 添加新功能"
git push origin main

# 6. 返回主仓库，更新子模块引用
cd ..
git add zh-blindauction
git commit -m "chore: 更新 zh-blindauction 子模块"
git push
```

#### 修改智能合约（fhevm-hardhat-template）

**注意**：`fhevm-hardhat-template` 是从 Zama 官方克隆的，通常不应直接修改。

如果需要修改：

```bash
# 1. Fork Zama 的仓库到你自己的 GitHub 账号
# 访问 https://github.com/zama-ai/fhevm-hardhat-template
# 点击右上角 "Fork" 按钮

# 2. 更新子模块 URL 为你的 Fork
git config -f .gitmodules submodule.fhevm-hardhat-template.url https://github.com/你的用户名/fhevm-hardhat-template.git
git submodule sync
git submodule update --init --remote

# 3. 现在可以像修改前端一样修改智能合约
cd fhevm-hardhat-template
# ... 进行修改、提交、推送
```

---

## 🔧 常用命令速查

| 命令 | 说明 |
|------|------|
| `git submodule status` | 查看所有子模块的状态 |
| `git submodule update --init` | 初始化并更新子模块 |
| `git submodule update --remote` | 更新子模块到最新版本 |
| `git submodule foreach git pull origin main` | 在每个子模块中执行 git pull |
| `git diff --submodule` | 查看子模块的差异 |
| `cat .gitmodules` | 查看子模块配置 |

---

## ⚠️ 常见问题

### 1. 子模块显示 "modified content"

**原因**：子模块内部有未提交的修改

**解决**：
```bash
# 进入子模块
cd zh-blindauction

# 查看状态
git status

# 提交或放弃修改
git add .
git commit -m "保存修改"
# 或
git restore .
```

### 2. 子模块显示 "untracked content"

**原因**：子模块中有未被 Git 跟踪的文件（如 node_modules）

**解决**：
```bash
# 检查子模块的 .gitignore
cd zh-blindauction
cat .gitignore

# 确保 node_modules 等目录已被忽略
```

### 3. 克隆后子模块目录是空的

**原因**：没有初始化子模块

**解决**：
```bash
git submodule update --init --recursive
```

### 4. 子模块处于 "detached HEAD" 状态

**原因**：子模块默认指向特定的提交，而非分支

**解决**：
```bash
cd zh-blindauction
git checkout main
git pull
cd ..
git add zh-blindauction
git commit -m "chore: 更新子模块到 main 分支"
```

---

## 📦 完整工作流示例

### 场景：为前端添加新功能

```bash
# 1. 确保主仓库是最新的
git pull

# 2. 更新所有子模块
git submodule update --init --recursive

# 3. 进入前端子模块
cd zh-blindauction

# 4. 切换到 main 分支并更新
git checkout main
git pull

# 5. 创建功能分支（可选）
git checkout -b feature/new-auction-filter

# 6. 进行开发...
# 编辑文件、测试等

# 7. 提交到前端仓库
git add .
git commit -m "feat: 添加拍卖筛选功能"

# 8. 推送到前端仓库
git push origin feature/new-auction-filter
# 如果在 main 分支：git push origin main

# 9. 返回主仓库
cd ..

# 10. 更新主仓库的子模块引用
git add zh-blindauction
git commit -m "chore: 更新 zh-blindauction 子模块（新增拍卖筛选）"

# 11. 推送主仓库
git push origin main
```

---

## 🎓 推荐学习资源

- [Git 官方文档 - 子模块](https://git-scm.com/book/zh/v2/Git-%E5%B7%A5%E5%85%B7-%E5%AD%90%E6%A8%A1%E5%9D%97)
- [GitHub 子模块教程](https://github.blog/2016-02-01-working-with-submodules/)

---

## 💡 最佳实践

1. **始终在子模块的正确分支上工作**
   ```bash
   cd zh-blindauction
   git checkout main
   ```

2. **提交前检查子模块状态**
   ```bash
   git submodule status
   git diff --submodule
   ```

3. **团队协作时，及时同步子模块**
   ```bash
   git pull
   git submodule update --init --recursive
   ```

4. **避免在主仓库中直接修改子模块文件**
   - 始终进入子模块目录
   - 在子模块中提交
   - 再回到主仓库更新引用

---

**最后更新**: 2026-02-08
**维护者**: BlindAuction Team
