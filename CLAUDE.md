# BlindAuction 项目开发指南（给 Claude AI 的完整指南）

> 本文档为 Claude AI 助手提供项目完整上下文，帮助快速理解架构并高效协助开发。

## 📋 项目概览

**BlindAuction** 是一个基于 FHEVM（全同态加密虚拟机）的去中心化盲拍平台，核心特性是隐私保护出价。

- **名称**: BlindAuction (盲拍平台)
- **版本**: 2.0.0
- **网络**: Sepolia Testnet (Chain ID: 11155111)
- **核心技术**: FHEVM (Zama), React 18, TypeScript 5.8, Hardhat, Solidity 0.8.27

## 🏗 项目架构

### 目录结构

```
BlindAuction/
├── fhevm-hardhat-template/        # 智能合约层（Git 子模块）
│   ├── contracts/                 # Solidity 合约
│   │   ├── BlindAuction.sol       # 核心拍卖合约（815 行）
│   │   ├── MySecretToken.sol      # ERC7984 加密代币
│   │   └── TokenExchange.sol      # ETH ⇄ SAT 兑换
│   ├── deploy/                    # Hardhat 部署脚本
│   ├── deployments/sepolia/       # Sepolia 部署地址
│   └── test/                      # 合约单元测试
│
├── zh-blindauction/               # 前端应用层（Git 子模块）
│   ├── src/
│   │   ├── pages/                # 8 个页面组件
│   │   │   ├── Auctions.tsx      # 拍卖列表页
│   │   │   ├── AuctionDetail.tsx # 拍卖详情页
│   │   │   ├── CreateAuction.tsx # 创建拍卖页
│   │   │   ├── Tokens.tsx        # 代币管理页
│   │   │   ├── Orders.tsx        # 订单跟踪页
│   │   │   └── Profile.tsx       # 用户资料页
│   │   ├── hooks/                # React 自定义 Hooks（核心业务逻辑）
│   │   │   ├── useAuctions.ts            # 拍卖数据获取（450 行）
│   │   │   ├── useCreateAuction.ts       # 创建拍卖逻辑
│   │   │   ├── useBid.ts                 # 出价逻辑
│   │   │   ├── useAuctionActions.ts      # 领取/物流/争议
│   │   │   ├── useSecretToken.ts         # SAT 代币操作
│   │   │   ├── useTokenExchange.ts       # ETH ⇄ SAT 兑换
│   │   │   ├── useTokenOperator.ts       # 代币授权
│   │   │   └── useWalletBalance.ts       # 钱包余额
│   │   ├── components/           # UI 组件库
│   │   │   ├── auction/          # 拍卖相关组件（6 个）
│   │   │   ├── layout/           # 布局组件
│   │   │   ├── wallet/           # 钱包连接
│   │   │   └── ui/               # shadcn/ui 组件库（50+ 组件）
│   │   ├── contexts/             # React Context
│   │   │   ├── FhevmProvider.tsx # FHEVM 实例管理（532 行，核心！）
│   │   │   └── Web3Provider.tsx  # wagmi + appkit 配置
│   │   ├── config/               # 配置文件
│   │   │   ├── contracts.ts      # 合约地址 + ABI（540 行，完整）
│   │   │   ├── wagmi.ts          # Wagmi 多 RPC 配置
│   │   │   └── i18n.ts           # 国际化配置
│   │   ├── lib/                  # 工具函数
│   │   │   ├── ipfs.ts           # IPFS 文件上传/下载
│   │   │   ├── supabase.ts       # Supabase 数据库
│   │   │   └── format.ts         # 格式化工具
│   │   ├── types/                # TypeScript 类型
│   │   └── mock/                 # Mock 数据存储（开发模式）
│   └── public/                   # 静态资源
│
├── scripts/                      # 工具脚本
│   ├── sync-contracts.js         # 同步合约地址到前端
│   └── dev-tools.js              # 开发工具菜单
│
└── docs/                         # 项目文档
    ├── CLAUDE.md                 # 本文档
    ├── DEVELOPMENT_STANDARDS.md  # 代码规范
    ├── FHEVM_RELAYER_SDK_INTEGRATION.md
    ├── GIT_SUBMODULE_GUIDE.md
    └── MANUAL_TEST_GUIDE.md
```

### 技术栈详情

#### 智能合约层
- **Solidity 0.8.27** - 合约语言
- **Hardhat** - 开发框架
- **FHEVM by Zama** - 全同态加密库（zama-dev/fhevm）
- **OpenZeppelin 5.1.0** - 安全标准库
- **ERC7984** - 加密代币标准

#### 前端层
- **React 18.3.1** + **TypeScript 5.8.3**
- **Vite 5.4.19** - 极快构建工具
- **wagmi 3.4.1** + **viem 2.45.0** - 区块链交互
- **@zama-fhe/relayer-sdk 0.4.0** - FHEVM 官方最新 SDK
- **@reown/appkit 1.8.17** - 多钱包连接（WalletConnect）
- **shadcn/ui** + **Radix UI** + **Tailwind CSS** - UI 框架
- **Framer Motion** - 动画库
- **i18next** - 国际化（中英文）
- **Supabase** - 后端数据库（评论、用户资料）

#### 区块链网络
- **Sepolia Testnet** (Chain ID: 11155111)
- **多 RPC 端点**：Infura（主）、PublicNode、RPC.sepolia.org、Tenderly、BlockPI

---

## 🔑 核心概念与机制

### 1. FHEVM（全同态加密）核心

#### 什么是 FHEVM？
FHEVM 允许智能合约直接操作加密数据，无需解密。这是区块链隐私保护的革命性技术。

**关键类型**：
- `euint64` - 加密的 64 位无符号整数（链上存储）
- `einput` - 加密输入（客户端生成）
- `ebool` - 加密布尔值

**关键函数**：
```solidity
// 验证加密输入并转换为 euint64
FHE.fromExternal(externalEuint64, inputProof) → euint64

// 加密域内比较（核心！）
FHE.lt(euint64 a, euint64 b) → ebool   // a < b
FHE.select(ebool cond, a, b) → euint64 // 三元运算

// 授权解密（给用户或合约权限）
FHE.allow(euint64 value, address account)

// 解密（需要密钥和签名）
FHE.decrypt(euint64 value) → uint64  // 仅测试用
```

#### 前端加密流程

```typescript
// 1. 创建加密输入
const input = await instance.createEncryptedInput(contractAddress, userAddress);

// 2. 添加明文数据
input.add64(bidAmount);  // 64 位整数

// 3. 加密
const encrypted = await input.encrypt();

// 返回值：
// {
//   handles: [bytes32],       // 加密后的 handle
//   inputProof: bytes          // 零知识证明
// }

// 4. 发送到合约
await contract.bid(auctionId, encrypted.handles[0], encrypted.inputProof);
```

#### 解密流程（需要用户签名）

```typescript
// 1. 生成密钥对
const { publicKey, privateKey } = instance.generateKeypair();

// 2. 创建 EIP-712 签名请求
const eip712 = instance.createEIP712(
  publicKey,
  contractAddress,
  userAddress,
  chainId
);

// 3. 用户签名（MetaMask 弹窗）
const signature = await signer._signTypedData(eip712.domain, eip712.types, eip712.message);

// 4. 通过 Relayer 解密
const decrypted = await instance.decryptEuint64(
  contractAddress,
  userAddress,
  encryptedHandle,  // bytes32
  publicKey,
  signature
);

// 返回明文：uint64
```

---

### 2. 拍卖状态机（核心业务逻辑）

```
┌─────────┐  startTime到达   ┌────────┐  endTime到达   ┌───────┐
│ Pending │ ──────────────→ │ Active │ ────────────→ │ Ended │
└─────────┘                  └────────┘                └───────┘
                                  │                       │
                                  │                       │ claim()
                                  │                       ↓
                            cancelAuction()          ┌─────────┐
                                  │                  │ Claimed │
                                  ↓                  └─────────┘
                            ┌───────────┐                │
                            │ Cancelled │                │ confirmShipment()
                            └───────────┘                ↓
                                              ┌───────────────┐
                                              │   Delivered   │
                                              └───────────────┘
                                                  │        │
                                                  │        │ raiseDispute()
                               confirmReceipt()   │        ↓
                                                  │   ┌──────────┐
                                                  │   │ Disputed │
                                                  ↓   └──────────┘
                                           ┌───────────┐
                                           │ Completed │
                                           └───────────┘
```

**状态定义**：
```solidity
enum AuctionStatus {
    Pending,      // 0 - 未开始
    Active,       // 1 - 进行中（可出价）
    Ended,        // 2 - 已结束（等待领取）
    Claimed,      // 3 - 已领取（等待发货）
    Delivered,    // 4 - 已发货（等待确认收货）
    Completed,    // 5 - 已完成
    Cancelled,    // 6 - 已取消
    Disputed      // 7 - 争议中
}
```

**状态转换规则**：
1. **Pending → Active**：`block.timestamp >= auctionStartTime`（自动）
2. **Active → Ended**：`block.timestamp >= auctionEndTime`（自动）
3. **Ended → Claimed**：获胜者调用 `claim()`（需支付 0.05 ETH 押金）
4. **Claimed → Delivered**：卖家调用 `confirmShipment(trackingInfo)`
5. **Delivered → Completed**：买家调用 `confirmReceipt()`（押金退还 + 代币支付）
6. **Delivered → Disputed**：买家调用 `raiseDispute(reason)`
7. **Disputed → Completed**：管理员调用 `adminArbitrate()`
8. **任何状态 → Cancelled**：卖家调用 `cancelAuction()`（仅限 Pending/Active）

---

### 3. 资金流转机制

#### 创建拍卖
- 卖家支付：**0.01 ETH** (LISTING_FEE)
- 接收地址：平台管理员
- 用途：防止垃圾拍卖

#### 出价
- 买家授权：BlindAuction 合约可转移 SAT 代币
- 不立即转移代币（仍在买家钱包）
- 链上只存储加密金额和出价者地址

#### 领取拍卖（claim）
- **获胜者**：
  - 支付 0.05 ETH 押金（SUCCESS_FEE）
  - SAT 代币转入托管（`escrowedTokens[auctionId]`）
  - 可随时提取押金（`withdrawStake()`）
- **失败者**：
  - 支付 0.05 ETH 押金
  - 代币立即退回（因为不是真正赢家）
  - 可立即提取押金

#### 确认收货
- 买家调用 `confirmReceipt()`
- 押金退还给买家（0.05 ETH）
- 托管代币支付给卖家：
  - 平台抽成：**10%**（PLATFORM_FEE_PERCENTAGE）
  - 卖家实得：**90%**

#### 争议仲裁
- 管理员调用 `adminArbitrate(auctionId, winner, buyerShare, sellerShare)`
- `buyerShare + sellerShare = 100`（百分比）
- 灵活分配：例如 60% 给买家，40% 给卖家

#### 超时自动解决
- 卖家发货后 30 天未确认收货
- 卖家调用 `claimEscrowAfterTimeout()`
- 自动给卖家全部代币（扣 10% 平台费）

---

### 4. 平局解决方案（创新！）

**问题**：多人出同样最高价，谁是赢家？

**解决方案**：三层比较机制

```solidity
// 比较两个出价者
function _compareWith(
    euint64 currentHighest,
    uint256 currentTimestamp,
    address currentWinner,
    euint64 newBid,
    uint256 newTimestamp,
    address newBidder
) internal returns (bool shouldReplace) {
    // 1️⃣ 价格比较（主要）
    ebool isHigher = FHE.lt(currentHighest, newBid);
    ebool isEqual = FHE.eq(currentHighest, newBid);

    // 2️⃣ 时间戳比较（次要）- 早者获胜
    bool isEarlier = newTimestamp < currentTimestamp;

    // 3️⃣ 地址比较（极端情况）- 字典序小者获胜
    bool isLowerAddress = uint256(uint160(newBidder)) < uint256(uint160(currentWinner));

    // 综合判断
    shouldReplace = FHE.decrypt(isHigher) ||
                    (FHE.decrypt(isEqual) && (isEarlier || (newTimestamp == currentTimestamp && isLowerAddress)));
}
```

**实际应用**：
- 用户 A 出价 1000 SAT，时间 10:00:00
- 用户 B 出价 1000 SAT，时间 10:00:01
- **结果**：用户 A 获胜（先到先得）

**claim() 函数的平局替换机制**：
- 如果有人声称自己是赢家（调用 `claim()`）
- 合约比较他的出价和当前 winner 的出价
- 如果确实更高（或平局但更早），则替换

---

### 5. 时间机制（重要！避免误解）

#### 区块链时间 (`block.timestamp`)
- **来源**：区块链矿工的时间戳
- **不可篡改**：一旦上链，永久记录
- **用途**：合约逻辑判断（拍卖状态）
- **精度**：秒级（Unix 时间戳）

#### 浏览器时间 (`Date.now()`)
- **来源**：用户本地设备
- **可篡改**：用户可修改系统时间
- **用途**：前端倒计时显示
- **精度**：毫秒级

**关键结论**：
- 修改浏览器时间 **不会** 影响拍卖状态
- 拍卖是否结束由 `block.timestamp >= auctionEndTime` 决定
- 前端倒计时只是 **视觉提示**

**代码示例**：
```typescript
// 前端倒计时组件（可能不准确）
const [timeLeft, setTimeLeft] = useState(endTime - Date.now());

// 合约状态判断（绝对准确）
function isAuctionActive() public view returns (bool) {
    return block.timestamp >= auctionStartTime &&
           block.timestamp < auctionEndTime;
}
```

---

## 📦 已部署合约地址（Sepolia）

| 合约名称 | 地址 | 主要功能 |
|---------|------|---------|
| MySecretToken | `0xAE4b8A28B69Ab86fb905Fc535e0F4B27bbe59243` | ERC7984 加密代币（SAT） |
| TokenExchange | `0xE1cD84947a301805229A1dE84B4Ca292600Ef0C6` | ETH ⇄ SAT 兑换（1 ETH = 1,000,000 SAT） |
| BlindAuction | `0x88C7976536790fB3918058a219CeD80093AeCEC9` | 核心拍卖合约 |

**查看合约**：https://sepolia.etherscan.io/address/[合约地址]

---

## 🛠 常见开发任务

### 任务 1：添加新的拍卖功能

**示例**：添加"延长拍卖"功能

1. **修改智能合约** (`BlindAuction.sol`)
   ```solidity
   // 添加函数
   function extendAuction(uint256 auctionId, uint256 additionalTime) external {
       require(msg.sender == auctions[auctionId].beneficiary, "Only seller");
       require(auctions[auctionId].status == AuctionStatus.Active, "Not active");
       auctions[auctionId].auctionEndTime += additionalTime;
       emit AuctionExtended(auctionId, additionalTime);
   }

   // 添加事件
   event AuctionExtended(uint256 indexed auctionId, uint256 additionalTime);
   ```

2. **重新部署合约**
   ```bash
   cd fhevm-hardhat-template
   npx hardhat compile
   npx hardhat deploy --network sepolia
   ```

3. **同步合约地址到前端**
   ```bash
   cd ..
   npm run sync
   ```

4. **更新前端 ABI** (`zh-blindauction/src/config/contracts.ts`)
   - 在 `BLIND_AUCTION_ABI` 数组中添加新函数的 ABI
   - 可以从 `deployments/sepolia/BlindAuction.json` 复制

5. **创建前端 Hook** (`zh-blindauction/src/hooks/useExtendAuction.ts`)
   ```typescript
   import { useWriteContract } from "wagmi";
   import { CONTRACT_ADDRESSES, BLIND_AUCTION_ABI } from "@/config/contracts";

   export function useExtendAuction() {
     const { writeContractAsync } = useWriteContract();

     const extend = async (auctionId: bigint, hours: number) => {
       const additionalTime = hours * 3600; // 转换为秒
       const tx = await writeContractAsync({
         address: CONTRACT_ADDRESSES.blindAuction,
         abi: BLIND_AUCTION_ABI,
         functionName: "extendAuction",
         args: [auctionId, BigInt(additionalTime)],
         gas: 200000n,
       });
       return tx;
     };

     return { extend };
   }
   ```

6. **更新 UI** (`zh-blindauction/src/pages/AuctionDetail.tsx`)
   ```tsx
   import { useExtendAuction } from "@/hooks/useExtendAuction";

   function AuctionDetail() {
     const { extend } = useExtendAuction();

     const handleExtend = async () => {
       await extend(auctionId, 24); // 延长 24 小时
       toast({ title: "拍卖已延长 24 小时" });
     };

     return <Button onClick={handleExtend}>延长拍卖</Button>;
   }
   ```

---

### 任务 2：使用 Mock 模式开发

**启用 Mock 模式**：

1. **设置环境变量** (`zh-blindauction/.env.local`)
   ```bash
   VITE_FHEVM_MOCK=true
   ```

2. **重启开发服务器**
   ```bash
   npm run dev
   ```

**Mock 模式特性**：
- ✅ 无需连接真实 Relayer（快速）
- ✅ 无需等待 WASM 加载（立即初始化）
- ✅ 使用本地内存数据库（`mockStore.ts`）
- ✅ 完全离线测试
- ✅ 所有操作有 1.2 秒模拟延迟（真实感）

**Mock 数据示例**：
```typescript
// mockStore.ts
export const MOCK_AUCTIONS = [
  {
    id: 0,
    beneficiary: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    title: "Rare NFT Artwork",
    minimumBid: 1000n,
    status: AuctionStatus.Active,
    // ...
  },
];

// 创建拍卖
export function createAuction(seller: string, metadata: string) {
  const newAuction = { /* ... */ };
  MOCK_AUCTIONS.push(newAuction);
  emitStoreChange(); // 触发 React 重新渲染
  return { success: true };
}
```

**切换回真实模式**：
```bash
# .env.local
VITE_FHEVM_MOCK=false
```

---

## 📚 关键文件位置速查

### 智能合约
| 文件 | 路径 | 说明 |
|-----|------|-----|
| 核心拍卖合约 | `fhevm-hardhat-template/contracts/BlindAuction.sol` | 815 行，所有拍卖逻辑 |
| 加密代币 | `fhevm-hardhat-template/contracts/MySecretToken.sol` | ERC7984 标准实现 |
| 代币兑换 | `fhevm-hardhat-template/contracts/TokenExchange.sol` | ETH ⇄ SAT |
| 部署脚本 | `fhevm-hardhat-template/deploy/deploy.ts` | Hardhat Deploy |
| 部署地址 | `fhevm-hardhat-template/deployments/sepolia/` | JSON 文件 |

### 前端核心
| 文件 | 路径 | 说明 |
|-----|------|-----|
| FHEVM 实例 | `zh-blindauction/src/contexts/FhevmProvider.tsx` | 532 行，FHEVM 初始化 |
| 合约配置 | `zh-blindauction/src/config/contracts.ts` | 540 行，完整 ABI |
| Wagmi 配置 | `zh-blindauction/src/config/wagmi.ts` | 多 RPC 端点 |
| 拍卖数据 | `zh-blindauction/src/hooks/useAuctions.ts` | 450 行，所有读取逻辑 |
| 拍卖操作 | `zh-blindauction/src/hooks/useAuctionActions.ts` | 领取/物流/争议 |
| 出价逻辑 | `zh-blindauction/src/hooks/useBid.ts` | 加密出价 |
| Mock 数据 | `zh-blindauction/src/mock/mockStore.ts` | 模拟数据库 |

---

## 🛠 开发命令速查

### 根目录命令
```bash
# 安装所有依赖（根目录 + 两个子模块）
npm run setup

# 启动前端开发服务器
npm run start

# 构建前端生产版本
npm run build

# 同步 Sepolia 合约地址到前端
npm run sync

# 同步本地合约地址到前端
npm run sync:local

# 开发工具菜单（交互式）
npm run tools
```

### 智能合约命令（fhevm-hardhat-template/）
```bash
# 编译所有合约
npx hardhat compile

# 部署到 Sepolia
npx hardhat deploy --network sepolia

# 部署到本地测试网络
npx hardhat node          # 终端 1：启动节点
npx hardhat deploy        # 终端 2：部署

# 运行合约测试
npx hardhat test

# 清理编译产物
npx hardhat clean

# 验证合约（Etherscan）
npx hardhat verify --network sepolia <合约地址> <构造函数参数>
```

### 前端命令（zh-blindauction/）
```bash
# 启动开发服务器（Vite，默认 5173 端口）
npm run dev

# 构建生产版本
npm run build

# 预览构建结果
npm run preview

# ESLint 检查
npm run lint

# 运行单元测试（Vitest）
npm run test

# 类型检查
npx tsc --noEmit
```

---

## 🐛 常见问题排查

### 前端问题

#### Q1: 交易失败（Gas limit too high）
**症状**：发送交易时报错"transaction gas limit too high"

**原因**：前端设置的 gas limit 超过区块上限（16777216）

**解决**：
- 已在 `useAuctionActions.ts` 中为所有函数设置合理的 gas limit
- 典型值：
  - `claim`: 500000（需要更多 gas）
  - 其他操作：300000

**检查代码**：
```typescript
// useAuctionActions.ts
const tx = await writeContractAsync({
  address: CONTRACT_ADDRESSES.blindAuction,
  abi: BLIND_AUCTION_ABI,
  functionName: "confirmShipment",
  args: [auctionId, trackingInfo],
  gas: 300000n,  // ← 确保设置
});
```

#### Q2: FHEVM 初始化超时
**症状**：加载超过 60 秒，显示"FHEVM 初始化失败"

**解决**：
1. 检查网络连接
2. 切换到 Mock 模式测试：
   ```bash
   # .env.local
   VITE_FHEVM_MOCK=true
   ```
3. 使用现代浏览器（Chrome 90+, Firefox 88+）
4. 清除浏览器缓存

#### Q3: 无法连接钱包
**排查步骤**：
1. 检查 MetaMask 是否已安装
2. 确认网络是否切换到 Sepolia（Chain ID: 11155111）
3. 打开浏览器控制台查看错误
4. 尝试刷新页面
5. 清除浏览器缓存和 LocalStorage

---

## ⚠️ 重要注意事项

### 安全考虑
1. **永远验证用户输入**：检查地址、金额、状态
2. **使用 ReentrancyGuard**：防止重入攻击
3. **管理员权限最小化**：仅在必要操作使用 `onlyOwner`
4. **FHEVM 特定风险**：
   - 加密数据无法直接读取（需授权解密）
   - Gas 消耗较高（加密操作复杂）
   - 需信任 Relayer（解密服务）

### Gas 优化
- FHEVM 操作（`FHE.lt`, `FHE.select`）消耗 **较高 gas**
- Sepolia 测试网免费，但主网需考虑成本

### 时间依赖
- **不要依赖 `block.timestamp` 的精确性**
- 区块时间戳可被矿工操作（±15 秒）

---

## 💡 协助建议（给 Claude AI）

当用户请求帮助时，请遵循以下原则：

### 1. 先读后写
- 在修改任何代码前，**先使用 Read 工具阅读相关文件**
- 理解现有代码逻辑和架构

### 2. 保持一致性
- 遵循项目现有的代码风格（TypeScript, ESLint 规则）
- 使用相同的命名约定（camelCase, PascalCase）

### 3. 最小改动
- 只修改必要的部分，避免过度重构
- 不要添加未请求的功能

### 4. 完整测试
- 提供测试步骤或建议用户如何验证
- 建议先使用 Mock 模式快速测试

### 5. 安全第一
- 特别注意智能合约的安全性
- FHEVM 操作需要仔细验证

### 6. 文档同步
- 如有重大改动，建议更新相关文档
- 在代码中添加清晰的注释

---

## 📖 学习资源

### 官方文档
- **Zama FHEVM**：https://docs.zama.ai/fhevm
- **Hardhat**：https://hardhat.org/docs
- **Wagmi**：https://wagmi.sh/
- **shadcn/ui**：https://ui.shadcn.com/

### 工具
- **Sepolia Faucet**：https://sepoliafaucet.com/
- **Sepolia Explorer**：https://sepolia.etherscan.io/

---

**最后更新**：2026-02-14
**维护者**：BlindAuction Team
**适用版本**：BlindAuction v2.0.0
