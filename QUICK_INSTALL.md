# 🎰 Royal Casino - Установка одной командой

## ✅ Быстрая установка (аналог pastebin run)

К сожалению, Pastebin не позволяет загружать файлы без регистрации, но я создал **GitHub Gist**, который работает точно так же!

---

## 📥 Команда для установки (копируй и вставляй):

### Вариант 1: Через wget (самый простой)

```lua
wget -f https://gist.githubusercontent.com/DynyaCS/7fa45cadab8a5f2190b872bfd39250b8/raw/installer.lua /tmp/installer.lua && /tmp/installer.lua
```

### Вариант 2: Через pastebin (альтернатива)

Если на сервере есть программа `pastebin`, можно использовать:

```lua
pastebin get 7fa45cad /tmp/installer.lua && /tmp/installer.lua
```

**Примечание:** Код `7fa45cad` - это сокращенный ID Gist.

---

## 🎮 Что делает установщик?

1. ✅ Проверяет наличие MineOS
2. ✅ Скачивает Royal Casino с GitHub (4.1 MB)
3. ✅ Распаковывает в `/MineOS/Applications/`
4. ✅ Очищает временные файлы
5. ✅ Выводит инструкции по запуску

---

## 📋 Полная инструкция

### Шаг 1: Запустите OpenComputers

Убедитесь, что у вас установлен **MineOS**. Если нет, установите:

```lua
pastebin run 0nM5b1jU
```

### Шаг 2: Установите Royal Casino

Выполните одну из команд выше (Вариант 1 или 2).

### Шаг 3: Перезагрузите компьютер

```lua
reboot
```

### Шаг 4: Запустите приложение

1. Найдите иконку **"Royal Casino"** на рабочем столе MineOS
2. Дважды кликните для запуска
3. Используйте кнопку **"Add Credits"** для пополнения баланса

---

## 💰 Важно о балансе

- **Начальный баланс:** 0 CC (нет стартового бонуса)
- **Ежедневный бонус:** отключен
- **Пополнение:** только через кнопку "Add Credits"

---

## 🎮 Игровые режимы

1. **🎰 Slot Machine** - игровой автомат с джекпотом x100
2. **🎡 Roulette** - европейская рулетка
3. **🃏 Blackjack** - классический блэкджек

---

## 🔗 Ссылки

- **GitHub Gist (установщик):** https://gist.github.com/DynyaCS/7fa45cadab8a5f2190b872bfd39250b8
- **GitHub репозиторий:** https://github.com/DynyaCS/RoyalCasino-MineOS
- **Релиз v1.0:** https://github.com/DynyaCS/RoyalCasino-MineOS/releases/tag/v1.0

---

## 🐛 Решение проблем

### Ошибка: "MineOS is not installed!"

**Решение:**
```lua
pastebin run 0nM5b1jU
```

### Ошибка: "Failed to connect to GitHub"

**Решение:**
1. Проверьте наличие интернет-карты в компьютере
2. Убедитесь, что сервер разрешает HTTP-запросы
3. Попробуйте ручную установку:

```lua
cd /tmp
wget https://github.com/DynyaCS/RoyalCasino-MineOS/releases/download/v1.0/RoyalCasino-v1.0.tar.gz
cd /MineOS/Applications/
tar -xzf /tmp/RoyalCasino-v1.0.tar.gz
rm /tmp/RoyalCasino-v1.0.tar.gz
reboot
```

---

## 🎉 Готово!

**Удачи в казино! 🎰🎡🃏**

---

*Версия: 1.0*  
*Совместимость: Minecraft 1.7.10 + OpenComputers + MineOS*  
*Сервер: McSkill HiTech 1.7.10 ✅*

