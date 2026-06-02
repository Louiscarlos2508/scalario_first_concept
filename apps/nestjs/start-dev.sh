#!/bin/sh
# Ensure postgres & redis resolve to 127.0.0.1
if ! grep -q ' postgres' /etc/hosts 2>/dev/null; then
  echo '127.0.0.1 postgres' | sudo tee -a /etc/hosts
fi
if ! grep -q ' redis' /etc/hosts 2>/dev/null; then
  echo '127.0.0.1 redis' | sudo tee -a /etc/hosts
fi

# Build if needed
[ ! -d dist ] && npm run build

# Start with correct DB users (scalario has BYPASSRLS → use scalario_app)
DATABASE_URL="postgresql://scalario_app@127.0.0.1:5432/scalario" \
DATABASE_URL_ADMIN="postgresql://scalario_admin@127.0.0.1:5432/scalario" \
exec node dist/main.js
