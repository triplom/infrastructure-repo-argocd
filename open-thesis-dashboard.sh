#!/bin/bash

echo "🎓 Opening Chapter 6 Thesis Dashboard..."
echo "========================================"

# Dashboard URL
DASHBOARD_URL="http://localhost:3001/d/d0d4f0ff-38cc-4187-bf0e-727d04456241/chapter-6-gitops-efficiency-evaluation-thesis-research"

echo ""
echo "📊 Chapter 6: GitOps Efficiency Evaluation - Thesis Research"
echo "🌐 URL: $DASHBOARD_URL"
echo "👤 Username: admin"
echo "🔐 Password: admin123"
echo ""

# Try to open in browser (works on most Linux systems)
if command -v xdg-open > /dev/null; then
    echo "🌐 Opening dashboard in browser..."
    xdg-open "$DASHBOARD_URL" 2>/dev/null || echo "Please manually open: $DASHBOARD_URL"
elif command -v open > /dev/null; then
    echo "🌐 Opening dashboard in browser..."
    open "$DASHBOARD_URL" 2>/dev/null || echo "Please manually open: $DASHBOARD_URL"
else
    echo "📋 Please copy and paste this URL into your browser:"
    echo "$DASHBOARD_URL"
fi

echo ""
echo "✅ Dashboard is ready for Chapter 6 thesis evaluation!"