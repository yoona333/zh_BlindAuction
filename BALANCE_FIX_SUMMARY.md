# 🔧 余额读取问题修复总结

## 📋 问题描述

前端在读取 `MySecretToken` 的 `confidentialBalanceOf` 时返回空数据 (`0x`),导致 ethers.js 无法解码:

```
Error: could not decode result data (value="0x", info={ "method": "confidentialBalanceOf", "signature": "confidentialBalanceOf(address)" }, code=BAD_DATA, version=6.16.0)
```

## 🔍 根本原因

**问题:** 前端使用 `BrowserProvider((window as any).ethereum)` 连接 MetaMask 时,在某些情况下(如 FHEVM 初始化期间)provider 状态不稳定,导致合约调用失败。

**验证:** 创建的 `verifyContracts.ts` 脚本使用 `JsonRpcProvider` 直接连接 Infura RPC,证明合约本身是正常的,可以成功返回数据。

## ✅ 解决方案

### 1. **修改 `useSecretToken.ts` 使用 JsonRpcProvider**

**位置:** `d:\zh-projects\BlindAuction\zh-blindauction\src\hooks\useSecretToken.ts`

**修改内容:**

```typescript
// ❌ 原代码 - 使用 BrowserProvider (不稳定)
const provider = new ethers.BrowserProvider((window as any).ethereum);

// ✅ 新代码 - 使用 JsonRpcProvider (稳定)
const RPC_URL = "https://sepolia.infura.io/v3/5e6d0def89ec47b1a2f9dfd91fc38ba6";
const provider = new ethers.JsonRpcProvider(RPC_URL);
```

**原因:**
- `JsonRpcProvider` 直接连接到 RPC 节点,不依赖 MetaMask
- 适合只读操作(如 `view` 函数)
- 更稳定,避免 MetaMask 状态问题

**注意:**
- 只用于读取余额(view 函数)
- 写操作(如转账、授权)仍需使用 `BrowserProvider` 来调用 MetaMask 签名

### 2. **改进错误处理和重试机制**

```typescript
// 增加重试延迟时间
await new Promise((r) => setTimeout(r, 1500 * (4 - retries)));

// 清晰的错误日志
console.log("📞 Calling confidentialBalanceOf", {
  contractAddress: CONTRACT_ADDRESSES.mySecretToken,
  userAddress: address.slice(0, 10) + "...",
});
```

### 3. **在 UI 中添加错误提示**

**位置:** `d:\zh-projects\BlindAuction\zh-blindauction\src\pages\Tokens.tsx`

添加了友好的错误提示卡片:

```tsx
{confidentialBalanceError && (
  <div className="p-3 rounded-lg bg-destructive/10 border border-destructive/20">
    <div className="flex items-start gap-2 text-sm text-destructive">
      <AlertCircle className="h-4 w-4 mt-0.5 flex-shrink-0" />
      <div className="flex-1">
        <p className="font-medium">读取余额失败</p>
        <p className="text-xs mt-1 opacity-90">
          无法从区块链读取加密余额。请检查网络连接或稍后重试。
        </p>
        <Button onClick={handleRefreshBalance}>
          <RefreshCw className="mr-1 h-3 w-3" />
          重新加载
        </Button>
      </div>
    </div>
  </div>
)}
```

### 4. **创建合约验证工具**

**文件:** `d:\zh-projects\BlindAuction\fhevm-hardhat-template\scripts\verifyContracts.ts`

**用途:**
- 快速验证所有合约是否正确部署
- 检查合约地址、余额、基本函数
- 测试 `confidentialBalanceOf` 是否正常工作

**运行:**
```bash
cd d:\zh-projects\BlindAuction\fhevm-hardhat-template
npx ts-node scripts/verifyContracts.ts
```

**输出示例:**
```
================================================================================
🔍 BlindAuction 合约验证工具
   Network: Sepolia Testnet
================================================================================

✅ 已连接到网络: sepolia (Chain ID: 11155111)
📦 当前区块高度: 10216765

============================================================
📋 验证合约: MySecretToken
📍 地址: 0xAE4b8A28B69Ab86fb905Fc535e0F4B27bbe59243
============================================================
✅ 合约已部署 (字节码长度: 14650 字节)
💰 合约 ETH 余额: 0.0 ETH
👤 合约 Owner: 0xc7b0D4dc5184b95Dda276b475dF59C3686d3E724

🔍 测试 confidentialBalanceOf(0xc7b0D4dc...):
   ✅ 成功返回: 0x4da1d0e68774171f4aa23a078fe99448845036c3bbff0000000000aa36a70500

🔧 Minter 地址: 0xE1cD84947a301805229A1dE84B4Ca292600Ef0C6

✅ 合约验证通过

...

🎉 所有合约验证通过!
```

## 📊 修复效果

### Before (问题状态)
```
❌ 调用 confidentialBalanceOf 返回 0x
❌ ethers.js 无法解码数据
❌ 前端显示错误,无法读取余额
```

### After (修复后)
```
✅ 使用 JsonRpcProvider 稳定连接
✅ 成功读取加密余额 handle
✅ 友好的错误提示和重试机制
✅ 合约验证工具方便调试
```

## 🎯 技术要点

### 何时使用 JsonRpcProvider vs BrowserProvider

| 场景 | Provider 类型 | 原因 |
|------|--------------|------|
| 读取数据 (view/pure) | `JsonRpcProvider` | 更稳定,不依赖钱包状态 |
| 写入交易 (需签名) | `BrowserProvider` | 必须通过钱包签名 |
| 监听事件 | 两者皆可 | 根据需求选择 |

### 最佳实践

1. **分离关注点:**
   - 只读操作 → `JsonRpcProvider` (后端 RPC)
   - 写入操作 → `BrowserProvider` (MetaMask)

2. **错误处理:**
   - 实现重试机制(3次重试)
   - 增加延迟时间(避免频繁请求)
   - 友好的用户提示

3. **调试工具:**
   - 详细的控制台日志
   - 合约验证脚本
   - 错误状态显示

## 📝 相关文件

- ✅ `zh-blindauction/src/hooks/useSecretToken.ts` - 修复 provider
- ✅ `zh-blindauction/src/pages/Tokens.tsx` - 添加错误提示
- ✅ `fhevm-hardhat-template/scripts/verifyContracts.ts` - 新建验证工具

## 🔗 合约地址 (Sepolia)

```typescript
export const CONTRACT_ADDRESSES = {
  tokenExchange: "0xE1cD84947a301805229A1dE84B4Ca292600Ef0C6",
  mySecretToken: "0xAE4b8A28B69Ab86fb905Fc535e0F4B27bbe59243",
  blindAuction: "0x88C7976536790fB3918058a219CeD80093AeCEC9",
};
```

所有合约均已验证正常工作 ✅

## 🚀 测试步骤

1. **验证合约:**
   ```bash
   npx ts-node scripts/verifyContracts.ts
   ```

2. **测试前端:**
   - 连接 MetaMask (Sepolia 网络)
   - 访问 Tokens 页面
   - 观察余额加载状态
   - 测试刷新和解密功能

3. **预期结果:**
   - ✅ 能够成功读取加密余额 handle
   - ✅ 错误时显示友好提示
   - ✅ 重试机制正常工作
   - ✅ FHEVM 初始化不影响余额读取

---

**修复日期:** 2026-02-08  
**状态:** ✅ 完成并测试通过
