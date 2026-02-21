# BlindAuction 项目宪法

> 本宪法定义了 BlindAuction 项目的开发规范、约束和最佳实践。所有开发者（包括 AI 助手）在修改代码时必须遵守这些规则。

---

## 📜 核心原则

### 1. 代码修改规范

#### 必须遵守
- ✅ **先读后写**：修改任何文件前必须先使用 Read 工具完整阅读该文件
- ✅ **最小改动原则**：只修改必要的部分，避免不必要的重构
- ✅ **保持一致性**：严格遵循项目现有的代码风格和架构模式
- ✅ **类型安全**：所有 TypeScript 代码必须通过类型检查
- ✅ **完整测试**：重要功能修改后必须在 Mock 模式和 Sepolia 测试网都验证通过

#### 禁止行为
- ❌ **不读文件直接修改**：可能破坏现有逻辑
- ❌ **使用 `any` 类型**：应使用明确的类型或 `unknown`
- ❌ **过度重构**：不要在修复 Bug 时顺便"优化"无关代码
- ❌ **删除错误处理**：即使代码看起来冗余，也不要轻易删除 try-catch
- ❌ **修改部署配置**：`deployments/sepolia/` 下的文件由部署脚本自动生成

---

### 2. 智能合约安全（零容忍）

#### 必须检查的安全问题
- 🔴 **重入攻击**：所有涉及资金转移的函数必须有 `nonReentrant` 修饰符
- 🔴 **整数溢出**：使用 Solidity 0.8+ 的内置检查，避免使用 `unchecked`
- 🔴 **权限绕过**：严格验证 `msg.sender`，使用 `onlyOwner` 保护管理员函数
- 🔴 **状态转换**：拍卖状态机转换必须严格按照规范执行
- 🔴 **加密数据验证**：FHEVM 操作必须正确使用 `FHE.fromExternal` 验证 inputProof

#### Gas 优化规范
- ⚡ FHEVM 操作（`FHE.lt`, `FHE.select`）消耗高 gas，尽量减少使用次数
- ⚡ 使用 `view` 函数读取数据，避免不必要的状态修改
- ⚡ 批量操作优于单个操作（如 `mintBatch` vs `mint`）
- ⚡ 合理设置 gas limit（见下方标准值）

---

### 3. 前端开发规范

#### 架构模式
- 📦 **React Hooks 优先**：所有业务逻辑封装在自定义 Hooks 中
- 📦 **组件职责单一**：每个组件只负责一个明确的功能
- 📦 **Context 适度使用**：仅用于 FHEVM、Web3、主题、语言等全局状态
- 📦 **避免 Props Drilling**：超过 3 层传递考虑使用 Context 或状态管理

#### 错误处理标准
```typescript
// ✅ 正确示例
try {
  const tx = await writeContractAsync({ /* ... */ });
  toast({ title: "成功", description: "操作成功完成" });
} catch (err) {
  const error = err instanceof Error ? err : new Error("操作失败");
  console.error("详细错误:", error);
  toast({
    title: "失败",
    description: error.message,
    variant: "destructive"
  });
}

// ❌ 错误示例
await writeContractAsync({ /* ... */ }); // 没有错误处理
```

#### 加载状态管理
- 🔄 所有区块链交互必须有加载状态（Loading/Pending/Success/Error）
- 🔄 使用 `useState` 管理状态或使用 Hook 返回的 `isLoading`
- 🔄 显示友好的加载提示（Spinner、骨架屏等）

---

### 4. FHEVM 集成规范

#### 必须遵守
- 🔐 **Mock 模式兼容**：所有 FHEVM 相关功能必须同时支持真实模式和 Mock 模式
- 🔐 **初始化检查**：使用 FHEVM 功能前必须检查 `isInitialized` 状态
- 🔐 **解密授权**：解密操作必须先检查用户授权（`FHE.allow`）
- 🔐 **错误降级**：FHEVM 失败时提供友好提示，建议切换到 Mock 模式

#### FHEVM 工作流程（标准）
```typescript
// 1. 加密流程
const input = await instance.createEncryptedInput(contractAddress, userAddress);
input.add64(bidAmount);
const encrypted = await input.encrypt();
await contract.bid(auctionId, encrypted.handles[0], encrypted.inputProof);

// 2. 解密流程
const { publicKey, privateKey } = instance.generateKeypair();
const eip712 = instance.createEIP712(publicKey, contractAddress, userAddress, chainId);
const signature = await signer._signTypedData(eip712.domain, eip712.types, eip712.message);
const decrypted = await instance.decryptEuint64(contractAddress, userAddress, handle, publicKey, signature);
```

---

## 🔧 技术栈约束

### 智能合约层（不可更改）
- **Solidity 版本**：`0.8.27`（固定版本，不升级）
- **框架**：Hardhat（不使用 Truffle 或 Foundry）
- **加密库**：`zama-dev/fhevm`（ERC7984 标准）
- **安全库**：`OpenZeppelin 5.1.0`

### 前端层（不可更改）
- **框架**：`React 18.3.1` + `TypeScript 5.8.3`
- **构建工具**：`Vite 5.4.19`（不使用 Webpack 或 CRA）
- **区块链库**：`wagmi 3.4.1` + `viem 2.45.0`（不直接使用 ethers.js）
- **FHEVM SDK**：`@zama-fhe/relayer-sdk 0.4.0`（官方最新 SDK）
- **UI 框架**：`shadcn/ui` + `Tailwind CSS`（不使用 Material-UI 或 Ant Design）
- **状态管理**：React Context + Custom Hooks（不引入 Redux 或 MobX）

### 可选依赖（需谨慎评估）
- 仅在绝对必要时引入新的 npm 包
- 优先使用已有依赖的功能
- 大型库（>100KB）需要充分理由

---

## ⛔ 绝对禁止事项

### 1. 合约相关
- ❌ **修改已部署合约地址**：`deployments/sepolia/*.json` 由部署脚本自动生成
- ❌ **绕过 gas limit 设置**：所有 `writeContractAsync` 必须显式设置 `gas` 参数
- ❌ **直接解密加密数据**：禁止尝试不通过 Relayer 解密 `euint64`
- ❌ **修改状态机逻辑**：拍卖状态转换经过仔细设计，不要轻易修改

### 2. 前端相关
- ❌ **使用 `any` 类型**：应使用明确的类型或 `unknown`
- ❌ **删除已有错误处理**：可能导致应用崩溃
- ❌ **修改子模块内容**：`fhevm-hardhat-template` 和 `zh-blindauction` 需单独提交

### 3. Git 相关
- ❌ **提交 `.env.local`**：包含敏感信息，已在 `.gitignore`
- ❌ **强制推送到主分支**：`git push --force` 可能覆盖他人工作
- ❌ **跳过 Git Hooks**：`--no-verify` 绕过代码检查

---

## 🔄 开发工作流程

### 添加新功能（完整流程）

#### 步骤 1：需求确认
- 明确功能需求和边界条件
- 确认是否需要修改智能合约
- 评估对现有功能的影响

#### 步骤 2：合约修改（如需要）
```bash
# 1. 编辑合约
cd fhevm-hardhat-template
# 修改 contracts/BlindAuction.sol 或其他合约

# 2. 编译
npx hardhat compile

# 3. 测试
npx hardhat test

# 4. 部署到 Sepolia
npx hardhat deploy --network sepolia

# 5. 同步地址到前端
cd ..
npm run sync
```

#### 步骤 3：前端适配
```bash
# 1. 更新 ABI（如有新函数）
# 编辑 zh-blindauction/src/config/contracts.ts

# 2. 创建或更新 Hook
# 在 zh-blindauction/src/hooks/ 目录

# 3. 更新 UI 组件
# 在 zh-blindauction/src/components/ 或 pages/
```

#### 步骤 4：测试验证
```bash
# 1. Mock 模式快速测试
# zh-blindauction/.env.local
# VITE_FHEVM_MOCK=true
npm run dev

# 2. Sepolia 真实测试
# VITE_FHEVM_MOCK=false
# 连接 MetaMask 测试
```

#### 步骤 5：文档更新
- 如有重大改动，更新 `CLAUDE.md`
- 在代码中添加清晰的注释
- 更新 `MANUAL_TEST_GUIDE.md`（如有新测试步骤）

---

### 修复 Bug（完整流程）

#### 步骤 1：问题诊断
```bash
# 检查浏览器控制台错误
# F12 → Console

# 查看 Sepolia Etherscan 交易失败原因
# https://sepolia.etherscan.io/

# 使用 Mock 模式排除 FHEVM 因素
# VITE_FHEVM_MOCK=true
```

#### 步骤 2：定位代码
- 使用 Grep 工具搜索相关函数或文件
- Read 工具阅读相关代码
- 理解现有逻辑再修改

#### 步骤 3：修复验证
- 修改代码（遵循最小改动原则）
- 本地测试（Mock 模式）
- Sepolia 测试（真实模式）
- 回归测试（确保没有破坏其他功能）

---

### Git 提交规范

#### 提交信息格式
```bash
# 格式：<type>: <description>
# type 可选值：
#   feat - 新功能
#   fix - Bug 修复
#   docs - 文档更新
#   style - 代码格式（不影响逻辑）
#   refactor - 重构
#   test - 测试相关
#   chore - 构建/工具相关

# 示例
git commit -m "feat: 添加延长拍卖功能"
git commit -m "fix: 修复 gas limit 超限问题"
git commit -m "docs: 更新 CLAUDE.md 文档"
```

#### 子模块提交流程
```bash
# 1. 提交合约子模块
cd fhevm-hardhat-template
git add .
git commit -m "feat: 添加延长拍卖功能"
git push

# 2. 提交前端子模块
cd ../zh-blindauction
git add .
git commit -m "feat: 实现延长拍卖 UI"
git push

# 3. 提交主项目（更新子模块引用）
cd ..
git add fhevm-hardhat-template zh-blindauction
git commit -m "chore: 更新子模块到最新版本"
git push
```

---

## 📁 常用文件路径（必须记忆）

### 智能合约核心
- `fhevm-hardhat-template/contracts/BlindAuction.sol` - **815 行**，拍卖核心逻辑
- `fhevm-hardhat-template/contracts/MySecretToken.sol` - ERC7984 加密代币
- `fhevm-hardhat-template/contracts/TokenExchange.sol` - ETH ⇄ SAT 兑换
- `fhevm-hardhat-template/deploy/deploy.ts` - 部署脚本
- `fhevm-hardhat-template/deployments/sepolia/` - 已部署合约信息（**自动生成，勿修改**）

### 前端核心
- `zh-blindauction/src/contexts/FhevmProvider.tsx` - **532 行**，FHEVM 初始化和管理
- `zh-blindauction/src/config/contracts.ts` - **540 行**，合约地址 + 完整 ABI
- `zh-blindauction/src/config/wagmi.ts` - Wagmi 配置，多 RPC 端点
- `zh-blindauction/src/hooks/useAuctions.ts` - **450 行**，拍卖数据获取
- `zh-blindauction/src/hooks/useAuctionActions.ts` - 领取/物流/争议操作
- `zh-blindauction/src/hooks/useBid.ts` - 加密出价逻辑
- `zh-blindauction/src/mock/mockStore.ts` - Mock 数据存储

### 配置和文档
- `CLAUDE.md` - **项目完整文档**（给 AI 的指南）
- `constitution.md` - **本文档**（开发规范）
- `DEVELOPMENT_STANDARDS.md` - 代码规范和最佳实践
- `MANUAL_TEST_GUIDE.md` - 手动测试流程
- `zh-blindauction/.env.local` - 环境变量（`VITE_FHEVM_MOCK` 等）

---

## 💡 关键业务逻辑（必须理解）

### 拍卖状态转换规则
```
Pending → Active → Ended → Claimed → Delivered → Completed
                                         ↓
                                     Disputed
                ↓
           Cancelled
```

**详细规则**：
1. `Pending → Active`：`block.timestamp >= auctionStartTime`（自动）
2. `Active → Ended`：`block.timestamp >= auctionEndTime`（自动）
3. `Ended → Claimed`：获胜者调用 `claim()`（需支付 0.05 ETH 押金）
4. `Claimed → Delivered`：卖家调用 `confirmShipment(trackingInfo)`
5. `Delivered → Completed`：买家调用 `confirmReceipt()`
6. `Delivered → Disputed`：买家调用 `raiseDispute(reason)`
7. `Disputed → Completed`：管理员调用 `adminArbitrate()`
8. `Pending/Active → Cancelled`：卖家调用 `cancelAuction()`

### 资金流转机制
1. **创建拍卖**：卖家支付 **0.01 ETH** 挂单费
2. **出价**：买家授权 SAT 代币（不立即转移）
3. **领取**：赢家支付 **0.05 ETH** 押金 + SAT 代币进入托管
4. **确认收货**：押金退还 + 卖家获得 **90%** SAT（**10%** 平台费）
5. **争议仲裁**：管理员灵活分配（如 60% 买家，40% 卖家）
6. **超时自动**：30 天后卖家可调用 `claimEscrowAfterTimeout()`

### Gas Limit 标准值
| 函数 | Gas Limit | 原因 |
|------|-----------|------|
| `createAuction` | 不设置 | 由钱包估算 |
| `bid` | 不设置 | FHEVM 操作复杂，难以预估 |
| `claim` | **500000** | 需要转移代币和 ETH |
| `withdrawStake` | **300000** | 标准值 |
| `confirmShipment` | **300000** | 标准值 |
| `confirmReceipt` | **300000** | 标准值 |
| `withdrawEscrow` | **300000** | 标准值 |
| `raiseDispute` | **300000** | 标准值 |

**重要**：Sepolia 区块 gas limit 上限为 **16777216**，不要超过此值！

---

## ⚡ 性能优化指南

### 合约层
- ✅ 使用 `view` 函数尽可能读取链上数据
- ✅ 批量操作优于单个操作（如 `mintBatch` vs `mint`）
- ✅ 减少加密比较次数（每次 `FHE.lt` 消耗大量 gas）
- ✅ 合理使用事件（Event）记录关键操作

### 前端层
- ✅ 使用 `useReadContracts` 批量读取多个拍卖数据
- ✅ 缓存 FHEVM 实例，避免重复初始化
- ✅ 使用 `React.memo` 和 `useMemo` 优化渲染
- ✅ 大列表使用虚拟滚动（如 `react-window`）
- ✅ 图片懒加载和 IPFS 图片优化

---

## 🧪 测试策略

### Mock 模式测试（快速迭代）
```bash
# zh-blindauction/.env.local
VITE_FHEVM_MOCK=true

# 启动开发服务器
npm run dev
```

**优势**：
- ⚡ 无需连接 Relayer（立即初始化）
- ⚡ 完全离线测试
- ⚡ 快速验证业务逻辑

### Sepolia 测试（真实环境）
```bash
# zh-blindauction/.env.local
VITE_FHEVM_MOCK=false

# 确保已部署最新合约
cd fhevm-hardhat-template
npx hardhat deploy --network sepolia

# 同步合约地址
cd ..
npm run sync

# 启动前端
npm run start
```

**必须测试的场景**：
- 🔍 钱包连接和网络切换
- 🔍 FHEVM 初始化和加密/解密
- 🔍 创建拍卖和出价
- 🔍 领取拍卖和物流流程
- 🔍 争议仲裁和超时处理

### 单元测试（合约层）
```bash
cd fhevm-hardhat-template
npx hardhat test
```

---

## 🌍 环境变量管理

### 必需的环境变量
```bash
# zh-blindauction/.env.local

# Mock 模式开关（开发时设为 true，生产设为 false）
VITE_FHEVM_MOCK=true

# Supabase 配置（评论功能）
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key

# WalletConnect Project ID（多钱包支持）
VITE_WALLETCONNECT_PROJECT_ID=your-project-id

# Infura API Key（可选，用于自定义 RPC）
VITE_INFURA_API_KEY=your-infura-key
```

### 敏感信息保护
- 🔒 `.env.local` 文件已在 `.gitignore` 中，**绝对不要提交**
- 🔒 生产环境使用环境变量注入，**不要硬编码**
- 🔒 合约私钥使用 Hardhat 的 `accounts` 配置，**不要直接写在代码中**
- 🔒 Supabase Key 仅使用 `anon` key，**不要暴露 `service_role` key**

---

## 🚀 部署流程

### Sepolia 测试网部署
```bash
# 1. 确保账户有足够的 Sepolia ETH
# 从 https://sepoliafaucet.com/ 获取

# 2. 编译合约
cd fhevm-hardhat-template
npx hardhat compile

# 3. 部署合约
npx hardhat deploy --network sepolia

# 4. 验证合约（可选）
npx hardhat verify --network sepolia <合约地址>

# 5. 同步地址到前端
cd ..
npm run sync

# 6. 测试部署
# 访问 https://sepolia.etherscan.io/address/[合约地址]
```

### 主网部署（未来）
- ⚠️ **不要在未经审计的情况下部署到主网**
- ⚠️ **先在 Sepolia 长期测试，确保稳定**
- ⚠️ **准备应急方案（Pausable、升级合约等）**

---

## 🔧 故障排查清单

### 前端无法连接钱包
- [ ] MetaMask 已安装
- [ ] 网络切换到 Sepolia（Chain ID: 11155111）
- [ ] 清除浏览器缓存和 LocalStorage
- [ ] 刷新页面重新连接

### FHEVM 初始化失败
- [ ] 网络连接正常（WASM 文件较大，约 10MB）
- [ ] 浏览器支持 WebAssembly（Chrome 90+, Firefox 88+）
- [ ] 尝试切换到 Mock 模式测试
- [ ] 检查控制台错误日志

### 交易失败
- [ ] 账户有足够的 Sepolia ETH
- [ ] Gas limit 设置合理（不超过 16777216）
- [ ] 拍卖状态正确（Active 才能出价，Ended 才能领取）
- [ ] 代币授权已完成（调用 `approve`）
- [ ] 查看 Etherscan 上的错误信息

### Mock 数据不同步
- [ ] `emitStoreChange()` 被调用
- [ ] `useEffect` 监听了 `MOCK_STORE_EVENT`
- [ ] 刷新页面重置 Mock 数据

---

## 🎯 代码审查清单

提交代码前，请自查以下项目：

### 智能合约
- [ ] 无安全漏洞（重入、溢出、权限）
- [ ] Gas 优化合理
- [ ] 事件定义完整
- [ ] 错误信息清晰
- [ ] 通过所有单元测试

### 前端代码
- [ ] TypeScript 无类型错误
- [ ] 无 `any` 类型
- [ ] 错误处理完整（try-catch）
- [ ] 加载状态管理（isLoading）
- [ ] 用户提示友好（toast）
- [ ] Mock 模式和真实模式都兼容

### Git 提交
- [ ] 提交信息符合规范
- [ ] 无敏感信息（.env.local）
- [ ] 子模块单独提交
- [ ] 代码格式化（ESLint/Prettier）

---

## 📚 延伸阅读

- **CLAUDE.md** - 项目完整技术文档
- **DEVELOPMENT_STANDARDS.md** - 代码规范和最佳实践
- **MANUAL_TEST_GUIDE.md** - 手动测试流程
- **Zama FHEVM 文档** - https://docs.zama.ai/fhevm
- **Wagmi 文档** - https://wagmi.sh/
- **Hardhat 文档** - https://hardhat.org/docs

---

**最后更新**：2026-02-14
**适用版本**：BlindAuction v2.0.0
**维护者**：BlindAuction Team

---

## 📝 变更日志

### v2.0.0 (2026-02-14)
- 初始版本
- 定义核心开发规范
- 添加完整的工作流程
- 添加故障排查清单

---

**遵守本宪法，构建更安全、更高效、更可维护的代码！** 🚀
