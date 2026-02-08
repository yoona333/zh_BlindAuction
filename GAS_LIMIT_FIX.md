# 🔧 授权解密 Gas Limit 问题修复

## ❌ 问题

调用 `setOperator` 时出现错误:
```
MetaMask - RPC Error: transaction gas limit too high 
(cap: 16777216, tx: 21000000)
```

同时解密仍然失败:
```
Error: Decryption returned no results
```

## 🔍 根本原因

1. **Gas Limit 过高**: `writeContract` 默认估算的 gas limit 为 21,000,000,超过了网络上限 16,777,216
2. **交易未确认**: 等待交易确认的逻辑不正确,导致解密时链上还没有授权记录

## ✅ 解决方案

### 1. 修复 Gas Limit

**文件:** `src/hooks/useTokenOperator.ts`

```typescript
writeContract({
  address: CONTRACT_ADDRESSES.mySecretToken,
  abi: MY_SECRET_TOKEN_ABI,
  functionName: "setOperator",
  args: [operatorAddress, BigInt(expiry)],
  gas: BigInt(200000), // 🔧 显式设置 gas limit
});
```

**原因:**
- `setOperator` 实际只需要 ~80,000 - 120,000 gas
- 设置 200,000 足够安全且不会超出限制

### 2. 修复等待交易确认逻辑

**文件:** `src/pages/Tokens.tsx`

**之前的代码:**
```typescript
await setOperator(); // ❌ 不会等待交易确认

await new Promise((resolve) => {
  const checkConfirm = setInterval(() => {
    if (isOperatorConfirmed) {
      clearInterval(checkConfirm);
      resolve(null);
    }
  }, 500);
});
```

**修复后:**
```typescript
setOperator(); // 触发交易

// ✅ 正确等待交易确认
let attempts = 0;
const maxAttempts = 60; // 最多等待 30 秒

while (attempts < maxAttempts) {
  if (isOperatorConfirmed && operatorTxHash) {
    break; // 交易已确认
  }
  await new Promise(r => setTimeout(r, 500));
  attempts++;
}

if (!isOperatorConfirmed || !operatorTxHash) {
  throw new Error("授权交易未确认,请重试");
}

// 再等待 2 秒确保链上状态已更新
await new Promise(r => setTimeout(r, 2000));
```

**关键改进:**
- 检查 `operatorTxHash` 确保交易已发送
- 检查 `isOperatorConfirmed` 确保交易已上链
- 额外等待 2 秒确保链上状态可读
- 超时处理避免无限等待

## 🎯 完整流程

### 用户点击解密按钮后:

```
1. 检查是否已授权
   ↓
2. [否] 调用 setOperator (gas: 200,000)
   ↓
3. 提示: "首次解密需要授权,请在钱包中确认"
   ↓
4. 用户在 MetaMask 确认交易
   ↓
5. 等待交易上链 (最多 30 秒)
   ↓
6. 检查 isOperatorConfirmed && operatorTxHash
   ↓
7. 等待 2 秒确保状态同步
   ↓
8. 设置 hasOperatorApproval = true
   ↓
9. 显示: "授权成功!"
   ↓
10. 调用 userDecrypt 解密余额
    ↓
11. 显示明文余额
```

## 📝 修改的文件

1. ✅ `src/hooks/useTokenOperator.ts` - 添加 gas limit
2. ✅ `src/pages/Tokens.tsx` - 修复等待确认逻辑
3. ✅ `scripts/testSetOperator.ts` - 新建测试脚本

## 🧪 测试脚本

运行测试验证函数调用:

```bash
cd d:\zh-projects\BlindAuction\fhevm-hardhat-template
npx ts-node scripts/testSetOperator.ts
```

## 🚀 测试步骤

1. **清除状态** - 刷新浏览器页面
2. **连接钱包** - Sepolia 测试网
3. **查看余额** - 确保有加密余额显示
4. **点击解密** 🔒
5. **观察流程:**
   - 提示 "首次解密需要授权"
   - MetaMask 弹出,Gas Limit 应该是 200,000
   - 确认交易
   - 等待 "授权成功!"
   - 自动开始解密
   - 显示明文余额

## ⚠️ 可能的问题

### 1. Gas Limit 仍然过高

如果仍然显示 21,000,000:
- 清除浏览器缓存
- 重启 MetaMask
- 检查 wagmi 版本

### 2. 交易确认超时

如果 30 秒内未确认:
- 检查网络拥堵情况
- 提高 Gas Price
- 在 Etherscan 查看交易状态

### 3. 解密仍然失败

如果授权成功但解密失败:
- 检查链上授权状态: `token.isOperator(address, address)`
- 增加等待时间 (从 2 秒增加到 5 秒)
- 查看 Relayer 日志

## 🔗 相关链接

- [Sepolia Etherscan](https://sepolia.etherscan.io/)
- [MySecretToken 合约](https://sepolia.etherscan.io/address/0xAE4b8A28B69Ab86fb905Fc535e0F4B27bbe59243)
- [Wagmi Gas 配置文档](https://wagmi.sh/react/api/actions/writeContract)

---

**修复日期:** 2026-02-08  
**状态:** ⏳ 等待测试验证
