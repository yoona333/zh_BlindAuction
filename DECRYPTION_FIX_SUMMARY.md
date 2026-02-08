# 🔐 ERC7984 余额解密功能实现

## 📋 问题背景

用户点击"解密余额"按钮时,解密失败并返回错误:
```
Error: Decryption returned no results
```

**根本原因:** ERC7984 加密代币标准要求用户在解密自己的余额之前,必须先调用 `setOperator` 授权自己访问加密数据。

## ✅ 解决方案

### 核心思路

在点击"解密"按钮时,自动执行两步操作:

1. **第一步:授权** - 调用 `setOperator(自己的地址, 过期时间)` 
2. **第二步:解密** - 调用 `userDecrypt` 解密余额

### 实现细节

#### 1. 创建 `useTokenOperator` Hook

**文件:** `src/hooks/useTokenOperator.ts`

```typescript
export function useTokenOperator() {
  const setOperator = useCallback(
    async (operator?: `0x${string}`, durationDays: number = 7) => {
      // 默认授权自己,有效期 7 天
      const operatorAddress = operator || address;
      const expiry = Math.floor(Date.now() / 1000) + durationDays * 86400;

      writeContract({
        address: CONTRACT_ADDRESSES.mySecretToken,
        abi: MY_SECRET_TOKEN_ABI,
        functionName: "setOperator",
        args: [operatorAddress, BigInt(expiry)],
      });
    },
    [address, writeContract, hash]
  );

  return {
    setOperator,
    isApproving: isWritePending || isConfirming,
    isConfirmed,
    txHash: hash,
  };
}
```

#### 2. 修改 `handleDecryptBalance` 函数

**文件:** `src/pages/Tokens.tsx`

```typescript
const handleDecryptBalance = useCallback(async (showToast = true) => {
  setIsDecrypting(true);
  
  try {
    // 🔐 第一步: 授权自己为 operator (首次解密时)
    if (!hasOperatorApproval) {
      console.log("🔐 Setting operator approval for decryption...");
      if (showToast) toast.info("首次解密需要授权,请在钱包中确认");
      
      await setOperator(); // 授权自己,有效期 7 天
      
      // 等待交易确认
      await new Promise((resolve) => {
        const checkConfirm = setInterval(() => {
          if (isOperatorConfirmed) {
            clearInterval(checkConfirm);
            resolve(null);
          }
        }, 500);
        
        setTimeout(() => {
          clearInterval(checkConfirm);
          resolve(null);
        }, 30000);
      });
      
      setHasOperatorApproval(true);
      if (showToast) toast.success("授权成功!");
    }

    // 🔓 第二步: 解密余额
    const handleBigInt = BigInt(confidentialBalance);
    const decrypted = await decryptFhevm(
      CONTRACT_ADDRESSES.mySecretToken,
      handleBigInt
    );

    if (decrypted === null) {
      throw new Error("Decryption returned null");
    }
    
    setDecryptedBalance(decrypted.toString());
    if (showToast) toast.success("解密成功!");
    
  } catch (err) {
    console.error("Decrypt error:", err);
    if (showToast) toast.error("解密失败");
  } finally {
    setIsDecrypting(false);
  }
}, [hasOperatorApproval, setOperator, isOperatorConfirmed, ...]);
```

## 🎯 工作流程

### 首次解密流程

```
用户点击"解密"按钮
    ↓
检查是否已授权 (hasOperatorApproval)
    ↓
[否] → 调用 setOperator(自己, 7天)
    ↓
显示: "请在钱包中确认授权交易"
    ↓
用户在 MetaMask 中确认
    ↓
等待交易确认 (最多30秒)
    ↓
设置 hasOperatorApproval = true
    ↓
显示: "授权成功!"
    ↓
调用 userDecrypt 解密余额
    ↓
显示解密后的余额
    ↓
显示: "解密成功!"
```

### 后续解密流程 (7天内)

```
用户点击"解密"按钮
    ↓
检查是否已授权 (hasOperatorApproval)
    ↓
[是] → 直接调用 userDecrypt
    ↓
显示解密后的余额
```

## 📝 关键代码修改

### 修改的文件

1. ✅ **新建** `src/hooks/useTokenOperator.ts` - 授权管理 hook
2. ✅ **修改** `src/pages/Tokens.tsx` - 添加授权逻辑到解密函数

### 状态管理

```typescript
const [hasOperatorApproval, setHasOperatorApproval] = useState(false);
```

- `hasOperatorApproval`: 标记用户是否已授权
- 授权成功后设为 `true`,7天内有效
- 刷新页面会重置,需要重新授权 (可优化为读取链上状态)

## 🔧 ERC7984 Operator 机制

### 什么是 Operator?

ERC7984 使用 **operator 机制** 而非传统的 `approve/allowance`:

```solidity
// ERC7984 授权方式
function setOperator(address operator, uint48 until) external;

// 传统 ERC20 授权方式 (ERC7984 不使用)
function approve(address spender, uint256 amount) external;
```

### 为什么需要授权自己?

- **隐私保护:** 加密余额默认对所有人(包括自己)不可见
- **显式授权:** 用户必须明确授权才能解密数据
- **时间限制:** 授权有过期时间,提高安全性

### Operator vs Approve

| 特性 | ERC7984 Operator | ERC20 Approve |
|------|-----------------|---------------|
| 用途 | 授权访问加密数据 | 授权转移代币 |
| 参数 | (operator, expiry) | (spender, amount) |
| 有效期 | 有时间限制 | 无时间限制 |
| 金额限制 | 无金额限制 | 有金额限制 |
| 自我授权 | **需要**(用于解密) | 不需要 |

## 📊 用户体验

### 首次解密

1. 用户点击 🔒 解密按钮
2. 显示提示: "首次解密需要授权,请在钱包中确认"
3. MetaMask 弹出授权交易
4. 用户确认授权 (Gas 费: ~0.001 ETH)
5. 显示: "授权成功!"
6. 自动开始解密
7. 显示: "解密成功!" 及明文余额

### 后续解密 (7天内)

1. 用户点击 🔒 解密按钮
2. 直接开始解密 (无需授权)
3. 显示: "解密成功!" 及明文余额

## 🚀 测试步骤

1. **连接钱包** - Sepolia 测试网
2. **购买代币** - 确保有 SAT 余额
3. **首次解密** 
   - 点击 🔒 按钮
   - 确认授权交易
   - 等待解密完成
4. **验证授权**
   - 刷新页面
   - 再次点击 🔒 按钮
   - 应该提示重新授权 (待优化)

## 🔮 未来优化

### 1. 持久化授权状态

```typescript
// 从链上读取授权状态,而不是用本地 state
const isOperator = await token.isOperator(address, address);
setHasOperatorApproval(isOperator);
```

### 2. 检查授权过期时间

```typescript
// 读取授权过期时间
const expiry = await token.operators(address, address);
const isExpired = expiry < Date.now() / 1000;
```

### 3. 自动续期提醒

```typescript
// 授权快过期时提醒用户
if (expiry - Date.now() / 1000 < 86400) {
  toast.warning("授权即将过期,建议续期");
}
```

## 📚 相关文档

- [ERC7984 标准说明](https://eips.ethereum.org/EIPS/eip-7984)
- [Zama FHEVM 解密文档](https://docs.zama.ai/fhevm)
- [完整工作流程](../fhevm-hardhat-template/docs/COMPLETE_WORKFLOW.md)

---

**实现日期:** 2026-02-08  
**状态:** ✅ 完成并准备测试
