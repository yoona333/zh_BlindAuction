#!/bin/bash

echo "==========================================="
echo "   BlindAuction 联调测试检查清单"
echo "==========================================="
echo ""

check_status() {
    if [ "$1" = "1" ]; then
        echo "✅ $2"
    else
        echo "❌ $2"
    fi
}

echo "📋 前置条件检查："
echo ""

# 检查 node_modules
if [ -d "zh-blindauction/node_modules" ]; then
    check_status 1 "前端依赖已安装"
else
    check_status 0 "前端依赖未安装 - 请运行: cd zh-blindauction && npm install"
fi

# 检查合约部署
if [ -f "fhevm-hardhat-template/deployments/sepolia/BlindAuction.json" ]; then
    check_status 1 "合约已部署到 Sepolia"
else
    check_status 0 "合约未部署 - 请运行: cd fhevm-hardhat-template && npx hardhat deploy --network sepolia"
fi

echo ""
echo "📝 测试步骤："
echo ""
echo "1. 启动前端: cd zh-blindauction && npm run dev"
echo "2. 打开浏览器: http://localhost:5173"
echo "3. 按照 TESTING_GUIDE.md 进行测试"
echo ""
echo "📖 详细测试指南: TESTING_GUIDE.md"
echo ""
