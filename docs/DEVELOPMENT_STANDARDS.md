# BlindAuction 开发规范与模块化指南

> 本文档定义 BlindAuction 项目的代码规范、架构模式和模块化原则，确保代码质量和团队协作效率。

## 📋 目录

- [代码风格规范](#代码风格规范)
- [项目架构原则](#项目架构原则)
- [智能合约规范](#智能合约规范)
- [前端开发规范](#前端开发规范)
- [模块化设计](#模块化设计)
- [Git 工作流程](#git-工作流程)
- [测试规范](#测试规范)
- [文档规范](#文档规范)

---

## 代码风格规范

### 通用规范

1. **缩进**: 2 空格（不使用 Tab）
2. **行宽**: 最大 100 字符
3. **换行**: Unix 风格（LF）
4. **编码**: UTF-8
5. **尾随空格**: 禁止
6. **文件结尾**: 保留一个空行

### TypeScript / JavaScript

```typescript
// ✅ 推荐
export const calculateTotal = (items: CartItem[]): number => {
  return items.reduce((sum, item) => sum + item.price, 0);
};

// ❌ 避免
export const calculateTotal = (items: CartItem[]): number =>
{
  return items.reduce((sum, item) => sum + item.price, 0)
}
```

**命名规范**:
- **文件名**: PascalCase（组件）、camelCase（工具函数）
  - `AuctionCard.tsx`（组件）
  - `useAuctions.ts`（Hook）
  - `formatDate.ts`（工具）

- **变量/函数**: camelCase
  ```typescript
  const auctionId = 1;
  const handleBidSubmit = () => {};
  ```

- **常量**: UPPER_SNAKE_CASE
  ```typescript
  const MAX_BID_AMOUNT = 1000000;
  const DEFAULT_LISTING_FEE = parseEther("0.01");
  ```

- **类型/接口**: PascalCase
  ```typescript
  interface AuctionData {
    id: bigint;
    title: string;
  }

  type AuctionStatus = "pending" | "active" | "ended";
  ```

- **React 组件**: PascalCase
  ```typescript
  export const AuctionCard: React.FC<AuctionCardProps> = ({ auction }) => {
    // ...
  };
  ```

### Solidity

```solidity
// ✅ 推荐
contract BlindAuction {
    uint256 public constant LISTING_FEE = 0.01 ether;
    uint256 private _auctionCounter;

    mapping(uint256 => Auction) private _auctions;

    function createAuction(string memory title) external payable {
        // ...
    }
}

// ❌ 避免
contract BlindAuction {
    uint256 public constant listingFee = 0.01 ether; // 应为 UPPER_CASE
    mapping(uint256 => Auction) auctions;  // 缺少可见性修饰符
}
```

**命名规范**:
- **合约名**: PascalCase
- **常量**: UPPER_SNAKE_CASE
- **状态变量**: 私有变量加前缀 `_`
- **函数**: camelCase
- **事件**: PascalCase

---

## 项目架构原则

### 1. 分层架构

```
┌─────────────────────────────────┐
│      UI Layer (Pages)           │  用户界面
├─────────────────────────────────┤
│   Component Layer (Components)  │  可复用组件
├─────────────────────────────────┤
│    Business Logic (Hooks)       │  业务逻辑
├─────────────────────────────────┤
│   Data Layer (Contexts/Config)  │  数据管理
├─────────────────────────────────┤
│   Blockchain Layer (Contracts)  │  智能合约
└─────────────────────────────────┘
```

**职责划分**:

- **UI Layer**: 仅负责展示和用户交互
- **Component Layer**: 无状态的可复用组件
- **Business Logic**: 状态管理、数据处理、合约调用
- **Data Layer**: 全局状态、配置管理
- **Blockchain Layer**: 智能合约逻辑

### 2. 单一职责原则（SRP）

每个模块/组件只负责一个功能：

```typescript
// ✅ 推荐 - 职责单一
export const useAuctions = () => {
  // 只负责获取拍卖列表
  return useReadContract({
    address: CONTRACTS.BlindAuction.address,
    abi: CONTRACTS.BlindAuction.abi,
    functionName: "getAuctions"
  });
};

export const useBidSubmit = () => {
  // 只负责提交出价
  const { writeContract } = useWriteContract();
  // ...
};

// ❌ 避免 - 职责混乱
export const useAuctionManager = () => {
  // 既管理列表，又处理出价，还做筛选...
};
```

### 3. 依赖倒置原则（DIP）

依赖抽象而非具体实现：

```typescript
// ✅ 推荐 - 依赖接口
interface ContractConfig {
  address: `0x${string}`;
  abi: any[];
}

const useContract = (config: ContractConfig) => {
  // 可适配任何合约
};

// ❌ 避免 - 硬编码依赖
const useBlindAuction = () => {
  const address = "0x34a1A618f97..."; // 硬编码
};
```

---

## 智能合约规范

### 1. 合约结构顺序

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./interfaces/IBlindAuction.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title BlindAuction
 * @notice 基于 FHEVM 的盲拍合约
 * @dev 使用 Zama 的全同态加密技术
 */
contract BlindAuction is ReentrancyGuard {
    // 1. 类型定义
    enum AuctionStatus { Pending, Active, Ended }

    struct Auction {
        uint256 id;
        address seller;
        uint256 startTime;
    }

    // 2. 状态变量
    uint256 private _auctionCounter;
    mapping(uint256 => Auction) private _auctions;

    // 3. 常量
    uint256 public constant LISTING_FEE = 0.01 ether;

    // 4. 事件
    event AuctionCreated(uint256 indexed auctionId, address indexed seller);

    // 5. 修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // 6. 构造函数
    constructor() {
        owner = msg.sender;
    }

    // 7. 外部函数
    function createAuction(...) external payable {
        // ...
    }

    // 8. 公开函数
    function getAuction(uint256 id) public view returns (Auction memory) {
        // ...
    }

    // 9. 内部函数
    function _validateAuction(...) internal view {
        // ...
    }

    // 10. 私有函数
    function _incrementCounter() private {
        // ...
    }
}
```

### 2. 安全检查清单

每个函数必须考虑：

```solidity
function claimAuction(uint256 auctionId) external payable nonReentrant {
    // ✅ 1. 输入验证
    require(auctionId > 0 && auctionId <= _auctionCounter, "Invalid auction ID");

    // ✅ 2. 状态检查
    Auction storage auction = _auctions[auctionId];
    require(auction.status == AuctionStatus.Ended, "Auction not ended");

    // ✅ 3. 权限检查
    require(auction.winner == msg.sender, "Not the winner");

    // ✅ 4. 金额验证
    require(msg.value == DEPOSIT_AMOUNT, "Incorrect deposit");

    // ✅ 5. 重入保护（nonReentrant 修饰符）

    // ✅ 6. 状态更新（Checks-Effects-Interactions 模式）
    auction.status = AuctionStatus.Claimed;

    // ✅ 7. 外部调用（最后执行）
    (bool success, ) = payable(auction.seller).call{value: listingFee}("");
    require(success, "Transfer failed");

    // ✅ 8. 事件发射
    emit AuctionClaimed(auctionId, msg.sender);
}
```

### 3. Gas 优化建议

```solidity
// ✅ 使用 calldata（只读参数）
function createAuction(string calldata title) external {
    // ...
}

// ✅ 使用 storage 指针（避免复制）
Auction storage auction = _auctions[auctionId];
auction.status = AuctionStatus.Ended;

// ✅ 批量操作减少循环
uint256[] memory ids = new uint256[](count);
for (uint256 i = 0; i < count; i++) {
    ids[i] = i + 1;
}

// ❌ 避免在循环中修改状态
for (uint256 i = 0; i < auctions.length; i++) {
    _totalCount++; // 每次写入 storage，gas 消耗高
}
```

---

## 前端开发规范

### 1. 组件设计原则

#### 组件分类

```typescript
// 1. 页面组件（Pages）- 路由级别
// src/pages/Auctions.tsx
export const Auctions = () => {
  const { auctions } = useAuctions();
  return (
    <div>
      <AuctionList auctions={auctions} />
    </div>
  );
};

// 2. 容器组件（Containers）- 业务逻辑
// src/components/auction/AuctionList.tsx
export const AuctionList: React.FC<{ auctions: Auction[] }> = ({ auctions }) => {
  const [filter, setFilter] = useState("");
  const filtered = auctions.filter(a => a.title.includes(filter));

  return (
    <div>
      {filtered.map(a => <AuctionCard key={a.id} auction={a} />)}
    </div>
  );
};

// 3. 展示组件（Presentational）- 纯 UI
// src/components/auction/AuctionCard.tsx
export const AuctionCard: React.FC<AuctionCardProps> = ({ auction }) => {
  return (
    <Card>
      <h3>{auction.title}</h3>
      <p>{auction.description}</p>
    </Card>
  );
};
```

#### Props 设计

```typescript
// ✅ 推荐 - 明确的接口定义
interface AuctionCardProps {
  auction: {
    id: bigint;
    title: string;
    description: string;
    endTime: bigint;
  };
  onBid?: (auctionId: bigint) => void;
  className?: string;
}

// ❌ 避免 - 模糊的 any 类型
interface AuctionCardProps {
  data: any;
  onClick: Function;
}
```

### 2. Hooks 设计模式

#### 自定义 Hook 模板

```typescript
// src/hooks/useAuctions.ts
import { useReadContract } from "wagmi";
import { CONTRACTS } from "@/config/contracts";

export const useAuctions = () => {
  const { data, isLoading, error, refetch } = useReadContract({
    address: CONTRACTS.BlindAuction.address,
    abi: CONTRACTS.BlindAuction.abi,
    functionName: "getAuctions",
    query: {
      refetchInterval: 10000, // 每 10 秒刷新
    }
  });

  // 数据转换逻辑
  const auctions = (data as any[])?.map((item, index) => ({
    id: BigInt(index + 1),
    title: item.title,
    // ...
  })) || [];

  return {
    auctions,
    isLoading,
    error,
    refetch
  };
};
```

#### Hook 职责划分

```typescript
// ✅ 读操作 Hook
export const useAuctions = () => {
  // 只负责获取数据
};

// ✅ 写操作 Hook
export const useBidSubmit = () => {
  // 只负责提交出价
};

// ✅ 复合操作 Hook（组合多个 Hook）
export const useAuctionActions = (auctionId: bigint) => {
  const { auctions } = useAuctions();
  const { submitBid } = useBidSubmit();

  const auction = auctions.find(a => a.id === auctionId);

  return { auction, submitBid };
};
```

### 3. 状态管理规范

#### Context 使用场景

```typescript
// ✅ 全局状态（跨多个页面）
// src/contexts/FhevmContext.tsx
export const FhevmProvider = ({ children }) => {
  const [fhevmInstance, setFhevmInstance] = useState<FhevmInstance | null>(null);

  // 全局使用的 FHEVM 实例
  return (
    <FhevmContext.Provider value={{ fhevmInstance }}>
      {children}
    </FhevmContext.Provider>
  );
};

// ✅ 局部状态（单页面）
export const Auctions = () => {
  const [filter, setFilter] = useState(""); // 不需要 Context
  // ...
};
```

### 4. 错误处理规范

```typescript
// ✅ 完整的错误处理
export const useBidSubmit = () => {
  const { writeContract } = useWriteContract();

  const submitBid = async (auctionId: bigint, amount: bigint) => {
    try {
      const hash = await writeContract({
        address: CONTRACTS.BlindAuction.address,
        abi: CONTRACTS.BlindAuction.abi,
        functionName: "bid",
        args: [auctionId, amount]
      });

      toast.success("出价成功！");
      return { success: true, hash };

    } catch (error: any) {
      // 分类错误处理
      if (error.message?.includes("user rejected")) {
        toast.error("您已取消交易");
      } else if (error.message?.includes("insufficient funds")) {
        toast.error("余额不足");
      } else {
        toast.error(`出价失败: ${error.message}`);
      }

      console.error("Bid submission error:", error);
      return { success: false, error };
    }
  };

  return { submitBid };
};
```

---

## 模块化设计

### 1. 目录组织原则

#### 按功能模块划分

```
src/
├── components/
│   ├── auction/           # 拍卖相关组件
│   │   ├── AuctionCard.tsx
│   │   ├── AuctionList.tsx
│   │   └── BidForm.tsx
│   ├── token/             # 代币相关组件
│   │   ├── TokenBalance.tsx
│   │   └── TokenExchange.tsx
│   └── layout/            # 布局组件
│       ├── Header.tsx
│       └── Footer.tsx
│
├── hooks/
│   ├── auction/           # 拍卖相关 Hooks
│   │   ├── useAuctions.ts
│   │   ├── useBidSubmit.ts
│   │   └── useAuctionDetail.ts
│   └── token/             # 代币相关 Hooks
│       ├── useTokenBalance.ts
│       └── useTokenExchange.ts
│
├── pages/                 # 页面级组件
│   ├── Auctions.tsx
│   ├── CreateAuction.tsx
│   └── TokenManagement.tsx
│
└── lib/                   # 工具函数
    ├── format.ts          # 格式化
    ├── validation.ts      # 验证
    └── constants.ts       # 常量
```

### 2. 模块导出规范

```typescript
// ✅ 使用 index.ts 统一导出
// src/components/auction/index.ts
export { AuctionCard } from "./AuctionCard";
export { AuctionList } from "./AuctionList";
export { BidForm } from "./BidForm";

// 使用时
import { AuctionCard, AuctionList } from "@/components/auction";

// ❌ 避免分散导入
import { AuctionCard } from "@/components/auction/AuctionCard";
import { AuctionList } from "@/components/auction/AuctionList";
```

### 3. 配置文件模块化

```typescript
// src/config/contracts.ts
export const CONTRACTS = {
  BlindAuction: {
    address: "0x34a1A618f97..." as `0x${string}`,
    abi: BlindAuctionABI
  },
  MySecretToken: {
    address: "0x168ecd6465..." as `0x${string}`,
    abi: MySecretTokenABI
  }
} as const;

// src/config/constants.ts
export const LISTING_FEE = parseEther("0.01");
export const DEPOSIT_AMOUNT = parseEther("0.05");
export const TOKEN_EXCHANGE_RATE = 1000000;

// src/config/chain.ts
export const SEPOLIA_CHAIN_ID = 11155111;
export const RPC_URL = "https://sepolia.infura.io/v3/...";
```

---

## Git 工作流程

### 1. 分支策略

```
main                  # 生产分支（仅部署版本）
  ├── develop         # 开发主分支
  │   ├── feature/auction-filter    # 功能分支
  │   ├── feature/token-exchange    # 功能分支
  │   ├── bugfix/bid-validation     # 修复分支
  │   └── hotfix/contract-security  # 紧急修复
```

### 2. 提交信息规范

```bash
# 格式: <type>(<scope>): <subject>

# Type:
# - feat: 新功能
# - fix: 修复 bug
# - docs: 文档更新
# - style: 代码格式（不影响功能）
# - refactor: 重构
# - test: 测试相关
# - chore: 构建/工具配置

# 示例:
git commit -m "feat(auction): 添加拍卖筛选功能"
git commit -m "fix(bid): 修复出价金额验证逻辑"
git commit -m "docs(readme): 更新部署指南"
git commit -m "refactor(hooks): 优化 useAuctions Hook 性能"
```

### 3. Pull Request 规范

```markdown
## 变更类型
- [ ] 新功能
- [x] Bug 修复
- [ ] 重构
- [ ] 文档更新

## 变更描述
添加了拍卖筛选功能，支持按状态、价格区间筛选。

## 影响范围
- `src/pages/Auctions.tsx`
- `src/hooks/useAuctions.ts`
- `src/components/auction/FilterBar.tsx`

## 测试步骤
1. 打开拍卖列表页
2. 使用筛选条件过滤
3. 验证结果正确性

## 截图（可选）
[附上功能截图]

## 相关 Issue
Closes #123
```

---

## 测试规范

### 1. 智能合约测试

```javascript
// test/BlindAuction.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BlindAuction", function () {
  let auction, owner, seller, bidder;

  beforeEach(async function () {
    [owner, seller, bidder] = await ethers.getSigners();
    const BlindAuction = await ethers.getContractFactory("BlindAuction");
    auction = await BlindAuction.deploy();
  });

  describe("创建拍卖", function () {
    it("应成功创建拍卖", async function () {
      await expect(
        auction.connect(seller).createAuction(
          "测试拍卖",
          "描述",
          1000,
          { value: ethers.parseEther("0.01") }
        )
      ).to.emit(auction, "AuctionCreated");
    });

    it("应拒绝不足的挂单费", async function () {
      await expect(
        auction.connect(seller).createAuction(
          "测试拍卖",
          "描述",
          1000,
          { value: ethers.parseEther("0.001") }
        )
      ).to.be.revertedWith("Insufficient listing fee");
    });
  });
});
```

### 2. 前端测试

```typescript
// src/hooks/__tests__/useAuctions.test.ts
import { renderHook } from "@testing-library/react";
import { useAuctions } from "../useAuctions";

describe("useAuctions", () => {
  it("应返回拍卖列表", async () => {
    const { result } = renderHook(() => useAuctions());

    expect(result.current.isLoading).toBe(true);

    await waitFor(() => {
      expect(result.current.auctions).toHaveLength(3);
    });
  });
});
```

### 3. 测试覆盖率要求

- **智能合约**: 至少 80% 覆盖率
- **核心业务逻辑**: 至少 70% 覆盖率
- **UI 组件**: 至少 50% 覆盖率

---

## 文档规范

### 1. 代码注释

```typescript
/**
 * 提交竞拍出价
 *
 * @param auctionId - 拍卖 ID
 * @param amount - 出价金额（SAT）
 * @returns 交易结果，包含成功状态和交易哈希
 *
 * @example
 * ```typescript
 * const { submitBid } = useBidSubmit();
 * await submitBid(1n, 1000n);
 * ```
 */
export const useBidSubmit = () => {
  // ...
};
```

### 2. README 模板

每个子模块应包含 README：

```markdown
# 模块名称

## 功能概述
简要描述模块的用途。

## 使用方法
```typescript
import { useAuctions } from "@/hooks/useAuctions";

const { auctions } = useAuctions();
```

## API 文档
### `useAuctions()`
返回拍卖列表。

**返回值**:
- `auctions: Auction[]` - 拍卖列表
- `isLoading: boolean` - 加载状态

## 相关文件
- `useAuctions.ts`
- `AuctionList.tsx`
```

### 3. 变更日志（CHANGELOG.md）

```markdown
# Changelog

## [2.0.0] - 2026-02-08

### Added
- 新增拍卖筛选功能
- 支持按状态、价格区间筛选

### Fixed
- 修复出价金额验证逻辑

### Changed
- 优化 FHEVM 初始化流程

### Removed
- 移除已废弃的本地部署支持
```

---

## 🔍 代码审查清单

在提交 PR 前，请确保：

### 通用检查
- [ ] 代码符合项目风格规范
- [ ] 没有 console.log / debugger
- [ ] 没有未使用的导入和变量
- [ ] 所有函数都有类型定义
- [ ] 关键逻辑有注释说明

### 智能合约
- [ ] 所有函数都有访问控制
- [ ] 使用了 ReentrancyGuard
- [ ] 输入参数都有验证
- [ ] 遵循 Checks-Effects-Interactions 模式
- [ ] 添加了事件发射
- [ ] 通过 Hardhat 测试

### 前端
- [ ] 组件职责单一
- [ ] Props 有明确的类型定义
- [ ] 错误处理完整
- [ ] 加载状态处理正确
- [ ] 无性能问题（避免不必要的渲染）

### 文档
- [ ] 更新了相关 README
- [ ] 添加了必要的注释
- [ ] 更新了 CHANGELOG

---

## 📞 联系与反馈

如有疑问或建议，请：
1. 提交 GitHub Issue
2. 联系项目维护者
3. 在团队会议中讨论

---

**最后更新**: 2026-02-08
**维护者**: BlindAuction Team
