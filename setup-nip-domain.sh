#!/bin/bash

# =============================================================================
# АВТОМАТИЧЕСКАЯ НАСТРОЙКА ДОМЕНА НА NIP.IO С LET'S ENCRYPT
# =============================================================================
# Скрипт автоматически настраивает VitePress сайт с SSL сертификатом
# на домене вида: IP.nip.io
# 
# Использование: ./setup-nip-domain.sh [PROJECT_NAME] [EMAIL]
# Пример: ./setup-nip-domain.sh my-site admin@example.com
# =============================================================================

set -e  # Остановить выполнение при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo -e "${BLUE}"
    echo "=============================================="
    echo "🚀 $1"
    echo "=============================================="
    echo -e "${NC}"
}

# Проверка прав root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Этот скрипт должен запускаться с правами root"
        exit 1
    fi
}

# Получение параметров
get_parameters() {
    # Получаем внешний IP
    EXTERNAL_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
    if [[ -z "$EXTERNAL_IP" ]]; then
        print_error "Не удалось определить внешний IP адрес"
        exit 1
    fi
    
    # Формируем nip.io домен
    NIP_DOMAIN="${EXTERNAL_IP}.nip.io"
    
    # Имя проекта
    PROJECT_NAME=${1:-"vitepress-site"}
    
    # Email для Let's Encrypt
    EMAIL=${2:-"admin@${NIP_DOMAIN}"}
    
    # Директория проекта
    PROJECT_DIR="/var/www/${PROJECT_NAME}"
    
    print_info "Внешний IP: $EXTERNAL_IP"
    print_info "Домен: $NIP_DOMAIN"
    print_info "Проект: $PROJECT_NAME"
    print_info "Email: $EMAIL"
    print_info "Директория: $PROJECT_DIR"
}

# Обновление системы
update_system() {
    print_header "ОБНОВЛЕНИЕ СИСТЕМЫ"
    
    apt update
    apt upgrade -y
    
    print_success "Система обновлена"
}

# Установка необходимых пакетов
install_packages() {
    print_header "УСТАНОВКА ПАКЕТОВ"
    
    # Основные пакеты
    apt install -y curl wget gnupg software-properties-common apt-transport-https ca-certificates
    
    # Nginx
    apt install -y nginx
    
    # Certbot для Let's Encrypt
    apt install -y certbot python3-certbot-nginx
    
    # Node.js (latest LTS)
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt install -y nodejs
    
    print_success "Все пакеты установлены"
    print_info "Node.js версия: $(node --version)"
    print_info "NPM версия: $(npm --version)"
}

# Настройка файрвола
setup_firewall() {
    print_header "НАСТРОЙКА ФАЙРВОЛА"
    
    # Устанавливаем UFW если не установлен
    apt install -y ufw
    
    # Базовые правила
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # Разрешаем SSH, HTTP и HTTPS
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Включаем файрвол
    ufw --force enable
    
    print_success "Файрвол настроен"
}

# Создание VitePress проекта
create_vitepress_project() {
    print_header "СОЗДАНИЕ VITEPRESS ПРОЕКТА"
    
    # Создаем директорию
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    # Инициализируем npm проект
    cat > package.json << EOL
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "VitePress site on $NIP_DOMAIN",
  "scripts": {
    "docs:dev": "vitepress dev",
    "docs:build": "vitepress build",
    "docs:preview": "vitepress preview"
  },
  "devDependencies": {
    "vitepress": "^1.6.3"
  }
}
EOL
    
    # Устанавливаем зависимости
    npm install
    
    # Создаем конфигурацию VitePress
    mkdir -p .vitepress
    cat > .vitepress/config.mts << EOL
import { defineConfig } from 'vitepress'

export default defineConfig({
  title: '$PROJECT_NAME',
  description: 'VitePress site hosted on $NIP_DOMAIN',
  
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Examples', link: '/markdown-examples' }
    ],

    sidebar: [
      {
        text: 'Examples',
        items: [
          { text: 'Markdown Examples', link: '/markdown-examples' },
          { text: 'Runtime API Examples', link: '/api-examples' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/vuejs/vitepress' }
    ]
  }
})
EOL
    
    # Создаем контент
    cat > index.md << EOL
---
layout: home

hero:
  name: "$PROJECT_NAME"
  text: "VitePress Site"
  tagline: "Powered by $NIP_DOMAIN"
  actions:
    - theme: brand
      text: Get Started
      link: /markdown-examples
    - theme: alt
      text: View on GitHub
      link: https://github.com/vuejs/vitepress

features:
  - title: Fast & Lightweight
    details: VitePress is built on top of Vite, providing instant server start and lightning-fast HMR.
  - title: Vue-Powered
    details: Enjoy the dev experience of Vue + webpack, use Vue components in markdown, and develop custom themes with Vue.
  - title: Performant
    details: VitePress generates pre-rendered static HTML for each page, and runs as an SPA once a page is loaded.
---
EOL
    
    cat > markdown-examples.md << EOL
# Markdown Extension Examples

This page demonstrates some of the built-in markdown extensions provided by VitePress.

## Syntax Highlighting

VitePress provides Syntax Highlighting powered by [Shiki](https://github.com/shikijs/shiki), with additional features like line-highlighting:

\`\`\`js{4}
export default {
  data () {
    return {
      msg: 'Highlighted!'
    }
  }
}
\`\`\`

## Custom Containers

::: info
This is an info box.
:::

::: tip
This is a tip.
:::

::: warning
This is a warning.
:::

::: danger
This is a dangerous warning.
:::

## Domain Information

- **Domain**: $NIP_DOMAIN
- **Project**: $PROJECT_NAME
- **SSL**: Let's Encrypt
- **Server**: Nginx + VitePress
EOL
    
    cat > api-examples.md << EOL
# Runtime API Examples

This page demonstrates usage of some of the runtime APIs provided by VitePress.

The main \`useData()\` API can be used to access site, theme, and page data for the current page. It works in both \`.md\` and \`.vue\` files:

\`\`\`md
<script setup>
import { useData } from 'vitepress'

const { theme, page, frontmatter } = useData()
</script>

## Results

### Theme Data
<pre>{{ theme }}</pre>

### Page Data
<pre>{{ page }}</pre>

### Page Frontmatter
<pre>{{ frontmatter }}</pre>
\`\`\`

<script setup>
import { useData } from 'vitepress'

const { site, theme, page, frontmatter } = useData()
</script>

## Results

### Site Data
<pre>{{ site }}</pre>

### Theme Data
<pre>{{ theme }}</pre>

### Page Data
<pre>{{ page }}</pre>

### Page Frontmatter
<pre>{{ frontmatter }}</pre>
EOL
    
    # Собираем проект
    npm run docs:build
    
    # Устанавливаем права
    chown -R www-data:www-data "$PROJECT_DIR"
    
    print_success "VitePress проект создан и собран"
}

# Настройка Nginx
setup_nginx() {
    print_header "НАСТРОЙКА NGINX"
    
    # Создаем конфигурацию
    cat > "/etc/nginx/sites-available/$PROJECT_NAME" << EOL
# HTTP Server Block
server {
    listen 80;
    listen [::]:80;
    server_name $NIP_DOMAIN;
    
    root $PROJECT_DIR/.vitepress/dist;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Static files optimization
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files \$uri =404;
    }
    
    # SPA routing - handle client-side routing
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy\\n";
        add_header Content-Type text/plain;
    }
    
    # Info endpoint
    location /info {
        add_header Content-Type application/json;
        return 200 '{"status":"online","domain":"$NIP_DOMAIN","project":"$PROJECT_NAME","ssl":"pending"}';
    }
    
    # Hide nginx version
    server_tokens off;
    
    # Logging
    access_log /var/log/nginx/${PROJECT_NAME}_access.log;
    error_log /var/log/nginx/${PROJECT_NAME}_error.log;
}
EOL
    
    # Активируем сайт
    ln -sf "/etc/nginx/sites-available/$PROJECT_NAME" "/etc/nginx/sites-enabled/"
    
    # Удаляем дефолтный сайт
    rm -f /etc/nginx/sites-enabled/default
    
    # Проверяем конфигурацию
    nginx -t
    
    # Перезапускаем Nginx
    systemctl restart nginx
    systemctl enable nginx
    
    print_success "Nginx настроен и запущен"
}

# Получение SSL сертификата
setup_ssl() {
    print_header "ПОЛУЧЕНИЕ SSL СЕРТИФИКАТА"
    
    print_info "Проверяем доступность домена..."
    
    # Ждем пока домен станет доступен
    for i in {1..10}; do
        if curl -s "http://$NIP_DOMAIN/health" > /dev/null; then
            print_success "Домен доступен!"
            break
        fi
        print_info "Попытка $i/10... Ждем 5 секунд"
        sleep 5
    done
    
    # Создаем директорию для ACME challenge
    mkdir -p "$PROJECT_DIR/.vitepress/dist/.well-known/acme-challenge"
    chown -R www-data:www-data "$PROJECT_DIR/.vitepress/dist/.well-known"
    
    # Получаем сертификат
    print_info "Получаем Let's Encrypt сертификат..."
    
    certbot certonly \
        --webroot \
        -w "$PROJECT_DIR/.vitepress/dist" \
        -d "$NIP_DOMAIN" \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive
    
    if [ $? -eq 0 ]; then
        print_success "SSL сертификат получен!"
        
        # Обновляем конфигурацию Nginx для HTTPS
        update_nginx_ssl
    else
        print_warning "Не удалось получить SSL сертификат. Сайт работает только по HTTP."
    fi
}

# Обновление конфигурации Nginx для SSL
update_nginx_ssl() {
    print_info "Обновляем Nginx конфигурацию для HTTPS..."
    
    cat > "/etc/nginx/sites-available/$PROJECT_NAME" << EOL
# HTTP Server Block - Redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $NIP_DOMAIN;
    
    # Health check для мониторинга
    location /health {
        access_log off;
        return 200 "healthy-http\\n";
        add_header Content-Type text/plain;
    }
    
    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS Server Block
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $NIP_DOMAIN;
    
    # Let's Encrypt SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$NIP_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$NIP_DOMAIN/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Root directory
    root $PROJECT_DIR/.vitepress/dist;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Static files optimization
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files \$uri =404;
    }
    
    # SPA routing - handle client-side routing
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # SSL Info endpoint
    location /ssl-info {
        add_header Content-Type application/json;
        return 200 '{"status":"encrypted","domain":"$NIP_DOMAIN","ssl":"Lets Encrypt","project":"$PROJECT_NAME"}';
    }
    
    # Info endpoint
    location /info {
        add_header Content-Type application/json;
        return 200 '{"status":"online","domain":"$NIP_DOMAIN","project":"$PROJECT_NAME","ssl":"active"}';
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy-ssl\\n";
        add_header Content-Type text/plain;
    }
    
    # Hide nginx version
    server_tokens off;
    
    # Logging
    access_log /var/log/nginx/${PROJECT_NAME}_ssl_access.log;
    error_log /var/log/nginx/${PROJECT_NAME}_ssl_error.log;
}
EOL
    
    # Перезагружаем Nginx
    nginx -t && systemctl reload nginx
    
    print_success "HTTPS конфигурация активирована"
}

# Настройка автообновления SSL
setup_ssl_renewal() {
    print_header "НАСТРОЙКА АВТООБНОВЛЕНИЯ SSL"
    
    # Добавляем задание в cron для автообновления
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet && /bin/systemctl reload nginx") | crontab -
    
    print_success "Автообновление SSL настроено"
}

# Создание управляющих скриптов
create_management_scripts() {
    print_header "СОЗДАНИЕ УПРАВЛЯЮЩИХ СКРИПТОВ"
    
    # Скрипт для обновления сайта
    cat > "/root/update-${PROJECT_NAME}.sh" << EOL
#!/bin/bash
# Скрипт для обновления $PROJECT_NAME

cd "$PROJECT_DIR"

echo "🔄 Обновляем VitePress сайт..."

# Устанавливаем обновления
npm update

# Пересобираем сайт
npm run docs:build

# Устанавливаем права
chown -R www-data:www-data .

# Перезагружаем Nginx
systemctl reload nginx

echo "✅ Сайт обновлен!"
echo "🌐 Доступен по адресу: https://$NIP_DOMAIN"
EOL
    
    chmod +x "/root/update-${PROJECT_NAME}.sh"
    
    # Скрипт для проверки статуса
    cat > "/root/status-${PROJECT_NAME}.sh" << EOL
#!/bin/bash
# Проверка статуса $PROJECT_NAME

echo "=== СТАТУС САЙТА $PROJECT_NAME ==="
echo
echo "🌐 Домен: $NIP_DOMAIN"
echo "📁 Проект: $PROJECT_DIR"
echo

echo "🔍 Nginx статус:"
systemctl is-active nginx

echo
echo "🔍 SSL сертификат:"
if [ -f "/etc/letsencrypt/live/$NIP_DOMAIN/fullchain.pem" ]; then
    openssl x509 -in "/etc/letsencrypt/live/$NIP_DOMAIN/fullchain.pem" -noout -dates
else
    echo "SSL сертификат не найден"
fi

echo
echo "🔍 HTTP тест:"
curl -s -o /dev/null -w "HTTP %{http_code}" "http://$NIP_DOMAIN/health" && echo

echo
echo "🔍 HTTPS тест:"
curl -s -o /dev/null -w "HTTPS %{http_code}" "https://$NIP_DOMAIN/health" && echo

echo
echo "📊 Логи Nginx (последние 5 строк):"
tail -5 "/var/log/nginx/${PROJECT_NAME}_access.log" 2>/dev/null || echo "Логи не найдены"
EOL
    
    chmod +x "/root/status-${PROJECT_NAME}.sh"
    
    print_success "Управляющие скрипты созданы:"
    print_info "  - /root/update-${PROJECT_NAME}.sh - обновление сайта"
    print_info "  - /root/status-${PROJECT_NAME}.sh - проверка статуса"
}

# Финальная проверка
final_check() {
    print_header "ФИНАЛЬНАЯ ПРОВЕРКА"
    
    # Проверяем HTTP
    print_info "Проверяем HTTP..."
    if curl -s "http://$NIP_DOMAIN/health" > /dev/null; then
        print_success "HTTP работает: http://$NIP_DOMAIN"
    else
        print_error "HTTP не работает!"
    fi
    
    # Проверяем HTTPS
    print_info "Проверяем HTTPS..."
    if curl -s "https://$NIP_DOMAIN/health" > /dev/null; then
        print_success "HTTPS работает: https://$NIP_DOMAIN"
    else
        print_warning "HTTPS не работает (возможно, SSL сертификат не получен)"
    fi
}

# Вывод итоговой информации
show_summary() {
    print_header "УСТАНОВКА ЗАВЕРШЕНА!"
    
    echo -e "${GREEN}"
    echo "🎉 ВАШ САЙТ ГОТОВ К ИСПОЛЬЗОВАНИЮ!"
    echo
    echo "📋 ИНФОРМАЦИЯ О ПРОЕКТЕ:"
    echo "   • Домен: $NIP_DOMAIN"
    echo "   • Проект: $PROJECT_NAME"
    echo "   • Директория: $PROJECT_DIR"
    echo "   • Email: $EMAIL"
    echo
    echo "🌐 АДРЕСА:"
    echo "   • HTTP:  http://$NIP_DOMAIN"
    echo "   • HTTPS: https://$NIP_DOMAIN"
    echo
    echo "🔧 УПРАВЛЕНИЕ:"
    echo "   • Обновить сайт: /root/update-${PROJECT_NAME}.sh"
    echo "   • Проверить статус: /root/status-${PROJECT_NAME}.sh"
    echo "   • Логи Nginx: /var/log/nginx/${PROJECT_NAME}*.log"
    echo
    echo "📝 РЕДАКТИРОВАНИЕ КОНТЕНТА:"
    echo "   • Файлы: $PROJECT_DIR/*.md"
    echo "   • Конфигурация: $PROJECT_DIR/.vitepress/config.mts"
    echo "   • После изменений: npm run docs:build"
    echo
    echo "🔄 АВТООБНОВЛЕНИЕ SSL:"
    echo "   • Настроено автоматическое обновление сертификата"
    echo "   • Проверяется ежедневно в 12:00"
    echo -e "${NC}"
}

# =============================================================================
# ОСНОВНАЯ ФУНКЦИЯ
# =============================================================================
main() {
    print_header "АВТОМАТИЧЕСКАЯ НАСТРОЙКА NIP.IO ДОМЕНА"
    
    # Проверки и подготовка
    check_root
    get_parameters "$@"
    
    # Основная установка
    update_system
    install_packages
    setup_firewall
    create_vitepress_project
    setup_nginx
    setup_ssl
    setup_ssl_renewal
    create_management_scripts
    
    # Финальные проверки
    final_check
    show_summary
    
    print_success "Скрипт выполнен успешно!"
}

# Запускаем основную функцию с переданными параметрами
main "$@"
