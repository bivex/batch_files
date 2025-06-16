# Russian Alphabet Learning Script
# Скрипт для изучения русского алфавита

# Установка кодировки вывода консоли в UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Глобальные данные алфавита
$Global:AlphabetData = @(
    @{Letter="А а"; Pronunciation="a (как в слове 'март')"; ExampleWord="Арбуз"; ExampleTranslation="watermelon"; SpokenLetter="А"; SpokenExample="Арбуз"},
    @{Letter="Б б"; Pronunciation="b (как в слове 'бок')"; ExampleWord="Банан"; ExampleTranslation="banana"; SpokenLetter="Бэ"; SpokenExample="Банан"},
    @{Letter="В в"; Pronunciation="v (как в слове 'вода')"; ExampleWord="Волк"; ExampleTranslation="wolf"; SpokenLetter="Вэ"; SpokenExample="Волк"},
    @{Letter="Г г"; Pronunciation="g (как в слове 'год')"; ExampleWord="Город"; ExampleTranslation="city"; SpokenLetter="Гэ"; SpokenExample="Город"},
    @{Letter="Д д"; Pronunciation="d (как в слове 'дом')"; ExampleWord="Дерево"; ExampleTranslation="tree"; SpokenLetter="Дэ"; SpokenExample="Дерево"},
    @{Letter="Е е"; Pronunciation="ye (как в слове 'ель')"; ExampleWord="Ель"; ExampleTranslation="spruce"; SpokenLetter="Е"; SpokenExample="Ель"},
    @{Letter="Ё ё"; Pronunciation="yo (как в слове 'ёлка')"; ExampleWord="Ёж"; ExampleTranslation="hedgehog"; SpokenLetter="Ё"; SpokenExample="Ёж"},
    @{Letter="Ж ж"; Pronunciation="zh (как в слове 'жук')"; ExampleWord="Жираф"; ExampleTranslation="giraffe"; SpokenLetter="Жэ"; SpokenExample="Жираф"},
    @{Letter="З з"; Pronunciation="z (как в слове 'звук')"; ExampleWord="Заяц"; ExampleTranslation="hare"; SpokenLetter="Зэ"; SpokenExample="Заяц"},
    @{Letter="И и"; Pronunciation="i (как в слове 'иголка')"; ExampleWord="Игра"; ExampleTranslation="game"; SpokenLetter="И"; SpokenExample="Игра"},
    @{Letter="Й й"; Pronunciation="y (краткий и, как в слове 'йод')"; ExampleWord="Йогурт"; ExampleTranslation="yogurt"; SpokenLetter="И краткое"; SpokenExample="Йогурт"},
    @{Letter="К к"; Pronunciation="k (как в слове 'кот')"; ExampleWord="Книга"; ExampleTranslation="book"; SpokenLetter="Ка"; SpokenExample="Книга"},
    @{Letter="Л л"; Pronunciation="l (как в слове 'луна')"; ExampleWord="Лев"; ExampleTranslation="lion"; SpokenLetter="Эль"; SpokenExample="Лев"},
    @{Letter="М м"; Pronunciation="m (как в слове 'мама')"; ExampleWord="Море"; ExampleTranslation="sea"; SpokenLetter="Эм"; SpokenExample="Море"},
    @{Letter="Н н"; Pronunciation="n (как в слове 'нос')"; ExampleWord="Небо"; ExampleTranslation="sky"; SpokenLetter="Эн"; SpokenExample="Небо"},
    @{Letter="О о"; Pronunciation="o (как в слове 'окно')"; ExampleWord="Орех"; ExampleTranslation="nut"; SpokenLetter="О"; SpokenExample="Орех"},
    @{Letter="П п"; Pronunciation="p (как в слове 'папа')"; ExampleWord="Птица"; ExampleTranslation="bird"; SpokenLetter="Пэ"; SpokenExample="Птица"},
    @{Letter="Р р"; Pronunciation="r (как в слове 'рука', раскатистый)"; ExampleWord="Рыба"; ExampleTranslation="fish"; SpokenLetter="Эр"; SpokenExample="Рыба"},
    @{Letter="С с"; Pronunciation="s (как в слове 'сон')"; ExampleWord="Солнце"; ExampleTranslation="sun"; SpokenLetter="Эс"; SpokenExample="Солнце"},
    @{Letter="Т т"; Pronunciation="t (как в слове 'том')"; ExampleWord="Трава"; ExampleTranslation="grass"; SpokenLetter="Тэ"; SpokenExample="Трава"},
    @{Letter="У у"; Pronunciation="u (как в слове 'утка')"; ExampleWord="Утро"; ExampleTranslation="morning"; SpokenLetter="У"; SpokenExample="Утро"},
    @{Letter="Ф ф"; Pronunciation="f (как в слове 'фото')"; ExampleWord="Фрукт"; ExampleTranslation="fruit"; SpokenLetter="Эф"; SpokenExample="Фрукт"},
    @{Letter="Х х"; Pronunciation="kh (как в слове 'хлеб')"; ExampleWord="Хлеб"; ExampleTranslation="bread"; SpokenLetter="Ха"; SpokenExample="Хлеб"},
    @{Letter="Ц ц"; Pronunciation="ts (как в слове 'цирк')"; ExampleWord="Цветок"; ExampleTranslation="flower"; SpokenLetter="Це"; SpokenExample="Цветок"},
    @{Letter="Ч ч"; Pronunciation="ch (как в слове 'час')"; ExampleWord="Чашка"; ExampleTranslation="cup"; SpokenLetter="Че"; SpokenExample="Чашка"},
    @{Letter="Ш ш"; Pronunciation="sh (как в слове 'шум')"; ExampleWord="Школа"; ExampleTranslation="school"; SpokenLetter="Ша"; SpokenExample="Школа"},
    @{Letter="Щ щ"; Pronunciation="shch (как в слове 'щука')"; ExampleWord="Щенок"; ExampleTranslation="puppy"; SpokenLetter="Ща"; SpokenExample="Щенок"},
    @{Letter="Ъ ъ"; Pronunciation="твёрдый знак (разделительный)"; ExampleWord="Подъезд"; ExampleTranslation="entrance"; SpokenLetter="Твёрдый знак"; SpokenExample="Подъезд"},
    @{Letter="Ы ы"; Pronunciation="y (грубый звук, нет в английском)"; ExampleWord="Сыр"; ExampleTranslation="cheese"; SpokenLetter="Ы"; SpokenExample="Сыр"},
    @{Letter="Ь ь"; Pronunciation="мягкий знак (смягчает согласные)"; ExampleWord="Пять"; ExampleTranslation="five"; SpokenLetter="Мягкий знак"; SpokenExample="Пять"},
    @{Letter="Э э"; Pronunciation="e (как в слове 'этот')"; ExampleWord="Эхо"; ExampleTranslation="echo"; SpokenLetter="Э"; SpokenExample="Эхо"},
    @{Letter="Ю ю"; Pronunciation="yu (как в слове 'юг')"; ExampleWord="Юбка"; ExampleTranslation="skirt"; SpokenLetter="Ю"; SpokenExample="Юбка"},
    @{Letter="Я я"; Pronunciation="ya (как в слове 'яблоко')"; ExampleWord="Яблоко"; ExampleTranslation="apple"; SpokenLetter="Я"; SpokenExample="Яблоко"}
)

# Инициализация синтезатора речи
$Global:TTS_Enabled = $false
$Global:SpeechSynthesizer = $null
try {
    Add-Type -AssemblyName System.Speech -ErrorAction Stop
    $Global:SpeechSynthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
    
    $russianVoice = $Global:SpeechSynthesizer.GetInstalledVoices() | Where-Object {$_.VoiceInfo.Culture.Name -eq 'ru-RU'} | Select-Object -First 1
    if ($russianVoice) {
        $Global:SpeechSynthesizer.SelectVoice($russianVoice.VoiceInfo.Name)
        Write-Host "Русский голос для синтезатора речи выбран: $($russianVoice.VoiceInfo.Name)" -ForegroundColor DarkGreen
    } else {
        Write-Host "Русский голос (ru-RU) не найден. Будет использован голос по умолчанию. Качество произношения может быть ниже." -ForegroundColor DarkYellow
    }
    $Global:TTS_Enabled = $true
    # Optional: Test speech
    # $Global:SpeechSynthesizer.SpeakAsync("Тест синтезатора речи.")
    Start-Sleep -Milliseconds 500 # Дать время прочитать сообщение и инициализироваться
} catch {
    Write-Warning "Не удалось инициализировать System.Speech.Synthesis.SpeechSynthesizer. Функция озвучивания будет недоступна. Ошибка: $($_.Exception.Message)"
    Start-Sleep -Seconds 3
}

function Show-AlphabetMenu {
    Clear-Host
    Write-Host "=== Изучение русского алфавита ===" -ForegroundColor Cyan
    Write-Host "1. Показать весь алфавит" -ForegroundColor Yellow
    Write-Host "2. Изучать буквы по порядку" -ForegroundColor Yellow
    Write-Host "3. Тренировка - угадай букву" -ForegroundColor Yellow
    Write-Host "4. Тренировка - угадай слово на букву" -ForegroundColor Yellow
    Write-Host "5. Показать алфавит списком" -ForegroundColor Yellow
    Write-Host "6. Выход" -ForegroundColor Yellow
    Write-Host "Выберите опцию (1-6): " -ForegroundColor Green -NoNewline
}

function Show-FullAlphabet {
    Clear-Host
    Write-Host "=== Русский алфавит ===" -ForegroundColor Cyan
    
    foreach ($entry in $Global:AlphabetData) {
        Write-Host ("Буква: " + $entry.Letter) -ForegroundColor Yellow
        Write-Host ("Произношение: " + $entry.Pronunciation) -ForegroundColor White
        Write-Host ("Пример: " + $entry.ExampleWord + " (" + $entry.ExampleTranslation + ")") -ForegroundColor Cyan
        Write-Host ""
    }
    
    Write-Host "Нажмите любую клавишу для возвращения в меню..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Learn-AlphabetSequentially {
    $index = 0
    
    while ($true) {
        Clear-Host
        
        $currentLetter = $Global:AlphabetData[$index]
        
        Write-Host "=== Изучение буквы ===" -ForegroundColor Cyan
        Write-Host ("Буква: " + $currentLetter.Letter) -ForegroundColor Yellow -BackgroundColor DarkGray
        Write-Host ("Произношение: " + $currentLetter.Pronunciation) -ForegroundColor White
        Write-Host ("Пример: " + $currentLetter.ExampleWord + " (" + $currentLetter.ExampleTranslation + ")") -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Навигация:" -ForegroundColor Green
        Write-Host "← Предыдущая буква (Left Arrow)" -ForegroundColor Gray
        Write-Host "→ Следующая буква (Right Arrow)" -ForegroundColor Gray
        if ($Global:TTS_Enabled) {
            Write-Host "P - Произнести букву и пример (клавиша P)" -ForegroundColor Gray
        }
        Write-Host "ESC - Вернуться в меню" -ForegroundColor Gray
        
        $keyInfo = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,AllowCtrlC")
        
        switch ($keyInfo.VirtualKeyCode) {
            37 { # Left Arrow
                $index = [Math]::Max(0, $index - 1)
            }
            39 { # Right Arrow
                $index = [Math]::Min($Global:AlphabetData.Length - 1, $index + 1)
            }
            27 { # Escape
                return
            }
            80 { # 'P' key
                if ($Global:TTS_Enabled) {
                    try {
                        Write-Host "`nПроизношу букву: $($currentLetter.SpokenLetter)..." -ForegroundColor DarkYellow
                        $Global:SpeechSynthesizer.Speak($currentLetter.SpokenLetter)
                        
                        Write-Host "Произношу пример: $($currentLetter.SpokenExample)..." -ForegroundColor DarkYellow
                        $Global:SpeechSynthesizer.Speak($currentLetter.SpokenExample)
                        Start-Sleep -Milliseconds 300 # Небольшая пауза перед очисткой экрана
                    } catch {
                        Write-Warning "`nОшибка воспроизведения звука: $($_.Exception.Message)"
                        Start-Sleep -Seconds 2
                    }
                }
            }
        }
    }
}

function Start-GuessLetterGame {
    Clear-Host
    Write-Host "=== Тренировка - Угадай букву ===" -ForegroundColor Cyan
    Write-Host "Я буду показывать вам букву русского алфавита, а вы должны ввести слово, начинающееся с этой буквы." -ForegroundColor White
    Write-Host "Нажмите любую клавишу, чтобы начать..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    $russianLetters = @("А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М", "Н", "О", "П", 
                        "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Э", "Ю", "Я")
    
    $score = 0
    $rounds = 10
    
    for ($i = 0; $i -lt $rounds; $i++) {
        Clear-Host
        $randomLetter = $russianLetters | Get-Random
        
        Write-Host "Раунд $($i+1) из $rounds" -ForegroundColor Yellow
        Write-Host "Счет: $score" -ForegroundColor Green
        Write-Host ""
        Write-Host "Буква: $randomLetter" -ForegroundColor Cyan -BackgroundColor DarkGray
        Write-Host "Введите слово, которое начинается с буквы '$randomLetter': " -ForegroundColor White -NoNewline
        
        $answer = Read-Host
        
        if ($answer -and $answer.ToUpper().StartsWith($randomLetter)) {
            Write-Host "Правильно! +1 очко" -ForegroundColor Green
            $score++
        } else {
            Write-Host "Неверно. Слово должно начинаться с буквы '$randomLetter'." -ForegroundColor Red
        }
        
        Start-Sleep -Seconds 1
    }
    
    Clear-Host
    Write-Host "=== Игра окончена ===" -ForegroundColor Yellow
    Write-Host "Ваш итоговый счет: $score из $rounds" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Нажмите любую клавишу для возвращения в меню..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-GuessWordGame {
    Clear-Host
    Write-Host "=== Тренировка - Угадай слово ===" -ForegroundColor Cyan
    Write-Host "Я покажу значение слова, а вы должны угадать само слово." -ForegroundColor White
    Write-Host "Нажмите любую клавишу, чтобы начать..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    $words = @(
        @{Word="Арбуз"; Hint="Большой круглый полосатый летний фрукт"},
        @{Word="Банан"; Hint="Желтый изогнутый фрукт"},
        @{Word="Вода"; Hint="Жидкость без цвета и запаха"},
        @{Word="Город"; Hint="Крупный населенный пункт"},
        @{Word="Дом"; Hint="Жилище, здание для проживания людей"},
        @{Word="Ель"; Hint="Вечнозеленое хвойное дерево"},
        @{Word="Ёжик"; Hint="Маленькое животное с иголками"},
        @{Word="Жираф"; Hint="Животное с очень длинной шеей"},
        @{Word="Зима"; Hint="Самое холодное время года"},
        @{Word="Игра"; Hint="Занятие для развлечения"},
        @{Word="Кот"; Hint="Домашнее животное, которое мяукает"},
        @{Word="Луна"; Hint="Спутник Земли"},
        @{Word="Море"; Hint="Большой водоем с соленой водой"},
        @{Word="Небо"; Hint="То, что над нами, где летают птицы"},
        @{Word="Окно"; Hint="Проем в стене для света и воздуха"},
        @{Word="Птица"; Hint="Существо с крыльями, которое умеет летать"},
        @{Word="Рыба"; Hint="Живет в воде и имеет чешую"},
        @{Word="Солнце"; Hint="Звезда, вокруг которой вращается Земля"},
        @{Word="Трава"; Hint="Зеленое растение с тонкими листьями"},
        @{Word="Утро"; Hint="Начало дня"}
    )
    
    $score = 0
    $rounds = 10
    $randomWords = $words | Get-Random -Count $rounds
    
    for ($i = 0; $i -lt $rounds; $i++) {
        Clear-Host
        $currentWord = $randomWords[$i]
        $firstLetter = $currentWord.Word.Substring(0, 1)
        
        Write-Host "Раунд $($i+1) из $rounds" -ForegroundColor Yellow
        Write-Host "Счет: $score" -ForegroundColor Green
        Write-Host ""
        Write-Host "Подсказка: $($currentWord.Hint)" -ForegroundColor Cyan
        Write-Host "Слово начинается на букву: $firstLetter" -ForegroundColor Yellow
        Write-Host "Ваш ответ: " -ForegroundColor White -NoNewline
        
        $answer = Read-Host
        
        if ($answer -and $answer.ToLower() -eq $currentWord.Word.ToLower()) {
            Write-Host "Правильно! +1 очко" -ForegroundColor Green
            $score++
        } else {
            Write-Host "Неверно. Правильный ответ: $($currentWord.Word)" -ForegroundColor Red
        }
        
        Start-Sleep -Seconds 2
    }
    
    Clear-Host
    Write-Host "=== Игра окончена ===" -ForegroundColor Yellow
    Write-Host "Ваш итоговый счет: $score из $rounds" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Нажмите любую клавишу для возвращения в меню..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-AlphabetList {
    Clear-Host
    Write-Host "=== Русский алфавит списком ===" -ForegroundColor Cyan
    
    $russianLetters = @(
        "А а", "Б б", "В в", "Г г", "Д д", "Е е", "Ё ё", "Ж ж", "З з", "И и", 
        "Й й", "К к", "Л л", "М м", "Н н", "О о", "П п", "Р р", "С с", "Т т", 
        "У у", "Ф ф", "Х х", "Ц ц", "Ч ч", "Ш ш", "Щ щ", "Ъ ъ", "Ы ы", "Ь ь", 
        "Э э", "Ю ю", "Я я"
    )
    
    $columns = 3
    $rows = [Math]::Ceiling($russianLetters.Count / $columns)
    
    Write-Host ""
    for ($i = 0; $i -lt $rows; $i++) {
        for ($j = 0; $j -lt $columns; $j++) {
            $index = $i + ($j * $rows)
            if ($index -lt $russianLetters.Count) {
                Write-Host $russianLetters[$index].PadRight(10) -ForegroundColor Yellow -NoNewline
            }
        }
        Write-Host ""
    }
    
    Write-Host "`nНажмите любую клавишу для возвращения в меню..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Основной цикл программы
$continue = $true

while ($continue) {
    Show-AlphabetMenu
    $choice = Read-Host
    
    switch ($choice) {
        "1" {
            Show-FullAlphabet
        }
        "2" {
            Learn-AlphabetSequentially
        }
        "3" {
            Start-GuessLetterGame
        }
        "4" {
            Start-GuessWordGame
        }
        "5" {
            Show-AlphabetList
        }
        "6" {
            $continue = $false
        }
        default {
            Write-Host "Неверный выбор, попробуйте еще раз." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

Write-Host "Спасибо за использование программы для изучения русского алфавита!" -ForegroundColor Green
Start-Sleep -Seconds 2 

