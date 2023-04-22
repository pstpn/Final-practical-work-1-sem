#!/bin/bash

#Stepan Postnov ICS7-11B

script_folder="$(realpath "$0" | sed 's/work.sh//g')"
#Предупреждение пользователя при запуске скрипта от имени суперпользователя
if [ $EUID -eq 0 ]; then 
	read -rp "Вы запустили скрипт от имени суперпользователя. Вы уверены, что хотите продолжить?[Y/n]: " Y_n
	if [[ $Y_n == "n" ]]; then
		exit 1
	fi
fi
#Создание скрытого файла .myconfig, если его нет в папке скрипта
if [ ! -e "$script_folder"".myconfig" ]; then
	echo "log " > "$script_folder"".myconfig"
	{
	echo "txt "
	echo "$script_folder"
	echo "grep error* last.txt > last.log"
	} >> "$script_folder"".myconfig"
fi
#Объявление переменных для упрощения работы скрипта
ext_temp=$(head -1 "$script_folder"".myconfig")
ext_work=$(head -2 "$script_folder"".myconfig" | tail -1)
work_folder=$(tail -2 "$script_folder"".myconfig" | head -1)
cur_command=$(tail -1 "$script_folder"".myconfig")
#Объявление функции, которая перезаписывает файл скрипта после изменения параметров
function change_myconfig {
	echo "$1" > "$script_folder"".myconfig"
	{
	echo "$2"
	echo "$3"
	echo "$4"
	} >> "$script_folder"".myconfig"
}
#_______Тихий режим_______
if [[ $1 == "show" ]]; then 
	if [ "$2" == "temp" ]; then #Вывод списка расширений временных файлов
		sch=0
		for i in $ext_temp; do
			sch=$((sch+1))
			echo $sch" расширение - *.""$i"
		done
	elif [ "$2" == "work" ]; then #Вывод списка расширений рабочих файлов
		sch=0
		for i in $ext_work; do
			sch=$((sch+1))
			echo $sch" расширение - *.""$i"
		done
	elif [ "$2" == "folder" ]; then #Вывод содержимого рабочей папки
		echo -e "Содержимое рабочей папки: \n""$(ls "$work_folder")"
	elif [ "$2" == "sw" ]; then #Вывод кол-ва строк и слов во всех рабочих файлах
		for i in $ext_work; do
			str=$(ls "$work_folder" | grep \."$i")
			if [[ $str =~ .+ ]]; then
				for j in "$work_folder"*."$i"; do
					echo "В файле $j: $(wc -l < "$j") строк и $(wc -w < "$j") слов"
				done
			fi
		done
	elif [ "$2" == "trash" ]; then #Вывод размера всех мусорных файлов
		for i in $ext_temp; do
			str=$(ls "$work_folder" | grep \."$i")
			if [[ $str =~ .+ ]]; then
				for j in "$work_folder"*."$i"; do
					echo "Файл $j имеет размер: $(wc -c < "$j") байтов"
				done
			fi
		done
	fi
elif [[ $1 == "add" ]]; then 
	if [ "$2" == "temp" ]; then #Добавление расширения в список расширений временных файлов
		ext_temp_new="$ext_temp ""$3"
		change_myconfig "$ext_temp_new" "$ext_work" "$work_folder" "$cur_command"
	elif [ "$2" == "work" ]; then #Добавление расширения в список расширений рабочих файлов
		ext_work_new="$ext_work ""$3"
		change_myconfig "$ext_temp" "$ext_work_new" "$work_folder" "$cur_command"
	fi
elif [[ $1 == "del" ]]; then
	if [ "$2" == "temp" ]; then
		if [ "$3" == "-a" ]; then #Удаление всех временных файлов в рабочей папке
			for i in $ext_temp; do
				find "$work_folder" -name "*.$i" -delete
			done
		else #Удаление конкретного расширения из списка расширений временных файлов
			r="\b""$3""\b" 
			ext_temp_new=$(echo "$ext_temp" | sed -E s/"$r"//g)
			change_myconfig "$ext_temp_new" "$ext_work" "$work_folder" "$cur_command"
		fi
	elif [ "$2" == "work" ]; then #Удаление конкретного расширения из списка расширений рабочих файлов
		r="\b""$3""\b"
		ext_work_new=$(echo "$ext_work" | sed -E s/"$r"//g)
		change_myconfig "$ext_temp" "$ext_work_new" "$work_folder" "$cur_command"
	elif [ "$2" == "config" ]; then #Удаление файла, содержащего настройки скрипта
		rm "$script_folder"".myconfig"
	fi
elif [[ $1 == "reload" ]]; then
	if [ "$2" == "temp" ]; then #Задать заново список расширений временных файлов
		ext_temp_new=""
		for i in "$@"; do
			if [ "$i" == "$1" ] || [ "$i" == "$2" ]; then
				continue
			else
				ext_temp_new="$ext_temp_new ""$i"
			fi
		done
		change_myconfig "$ext_temp_new" "$ext_work" "$work_folder" "$cur_command"
	elif [ "$2" == "work" ]; then #Задать заново список расширений рабочих файлов
		ext_work_new=""
		for i in "$@"; do
			if [ "$i" == "$1" ] || [ "$i" == "$2" ]; then
				continue
			else
				ext_work_new="$ext_work_new ""$i"
			fi
		done
		change_myconfig "$ext_temp" "$ext_work_new" "$work_folder" "$cur_command"
	elif [ "$2" == "folder" ]; then #Изменение рабочей папки скрипта
		change_myconfig "$ext_temp" "$ext_work" "$3" "$cur_command"
	elif [ "$2" == "command" ]; then #Изменение записанной команды скрипта 
		new_command=""
		for i in "$@"; do
			if [ "$i" == "$1" ] || [ "$i" == "$2" ]; then
				continue
			else
				new_command="$new_command ""$i"
			fi
		done
		change_myconfig "$ext_temp" "$ext_work" "$work_folder" "$new_command"
	fi
elif [[ $1 == "do" ]]; then #Исполнение записанной команды скрипта 
	eval "$cur_command"
else
	while :; do
		echo -e "\n======================================="
#Вывод списка расширений всех временных файлов
		echo -e "\033[43m\033[30mСписок расширений временных файлов:\033[37m\033[0m\n"
		sch=0
			for i in $ext_temp; do
				sch=$((sch+1))
				echo $sch" расширение - *.""$i"
			done
#Вывод списка расширений всех рабочих файлов
		echo -e "\n\033[43m\033[30mСписок расширений рабочих файлов:\033[37m\033[0m\n"
		sch=0
			for i in $ext_work; do
				sch=$((sch+1))
				echo $sch" расширение - *.""$i"
			done
#Вывод текущей записанной команды скрипта
		echo -e "\n\033[43m\033[30mЗаписанная команда скрипта:\033[37m\033[0m \033[36m<<\033[37m$cur_command\033[36m>>\033[37m\n"
#Вывод текущей рабочей папки скрипта
		echo -e "\n\033[43m\033[30mТекущая рабочая папка скрипта:\033[37m\033[0m $work_folder"
#Вывод интерфейса меню
		echo -e "\n\033[33m1. Задать заново список временных файлов 
2. Добавить или удалить конкретное расширение из списка временных файлов
3. Задать заново список рабочих файлов
4. Добавить или удалить конкретное расширение из списка рабочих файлов
5. Просмотреть или задать заново рабочую папку скрипта
6. Удалить временные файлы
7. Выполнить или изменить записанную команду
8. Просмотреть число строк и слов в каждом рабочем файле
9. Просмотреть объем каждого мусорного файла
0. Выход из меню\033[37m\n"
		read -rp "Введите желаемый номер меню: " n #Ввод желаемого номера пункта пользователем
		if [[ $n == "1" ]]; then #Задать заново список расширений временных файлов
			read -rp "Введите название нового расширения файлов: " name
			ext_temp="$name"
			while :; do
				read -rp "Введите название нового списка расширений или нажмите \"Enter\" для выхода: " name
				if [ -n "$name" ]; then
					ext_temp="$ext_temp"" ""$name"
				else
					break
				fi
			done
			echo -e "\n\033[33m_______Список задан заново_______\033[37m\n"
		elif [[ $n == "2" ]]; then
			echo "Выберите необходимый пункт:
1 -- Добавить конкретное расширение
2 -- Удалить конкретное расширение (по значению)"
			read -rp ": " number
			if [[ $number == "1" ]]; then #Добавление конкретного расширения в список временных расширений
				read -rp "Введите расширение, которое вы хотите добавить: " ext_add
				ext_temp="$ext_temp""$ext_add "
				echo -e "\n\033[33m_______Расширение добавлено_______\033[37m\n"
			elif [[ $number == "2" ]]; then #Удаление конкретного расширения из списка временных расширений
				read -rp "Введите расширение, которое вы хотите удалить: " ext_rem
				r="\b""$ext_rem""\b"
				ext_temp=$(echo "$ext_temp" | sed -E s/"$r"//g)
				echo -e "\n\033[33m_______Расширение удалено_______\033[37m\n"
			fi
		elif [[ $n == "3" ]]; then #Задать заново список расширений временных файлов
			read -rp "Введите название нового расширения файлов: " name
			ext_work="$name"
			while :; do
				read -rp "Введите название нового списка расширений или \"Enter\" для выхода: " name
				if [ -n "$name" ]; then
					ext_work="$ext_work"" ""$name"
				else
					break
				fi
			done
			echo -e "\n\033[33m_______Список задан заново_______\033[37m\n"
		elif [[ $n == "4" ]]; then
			echo "Выберите необходимый пункт:
1 -- Добавить конкретное расширение
2 -- Удалить конкретное расширение (по значению)"
			read -rp ": " number
			if [[ $number == "1" ]]; then #Добавление расширения в список расширений рабочих файлов
				read -rp "Введите расширение, которое вы хотите добавить: " ext_add
				ext_work="$ext_work""$ext_add "
				echo -e "\n\033[33m_______Расширение добавлено_______\033[37m\n"
			elif [[ $number == "2" ]]; then #Удаление конкретного расширения из списка расширений рабочих файлов
				read -rp "Введите расширение, которое вы хотите удалить: " ext_rem
				r="\b""$ext_rem""\b"
				ext_work=$(echo "$ext_work" | sed -E s/"$r"//g)
				echo -e "\n\033[33m_______Расширение удалено_______\033[37m\n"
			fi
		elif [[ $n == "5" ]]; then
			echo "Выберите необходимый пункт:
1 -- Просмотреть рабочую папку
2 -- Задать заново рабочую папку"
			read -rp ": " number
			if [[ $number == "1" ]]; then #Просмотр содержимого рабочей папки
				echo -e "\n\033[33mСодержимое рабочей папки:\033[37m \n""$(ls "$work_folder")"
			elif [[ $number == "2" ]]; then #Задать заново рабочую папку
				read -rp "Введите путь к новой рабочей папке: " work_folder
				work_folder=${work_folder//'~'/$HOME}
				echo -e "\n\033[33m_______Рабочая папка задана_______\033[37m\n"
			fi
		elif [[ $n == "6" ]]; then #Удаление всех временных файлов в рабочей папке
			for i in $ext_temp; do
				find "$work_folder" -name "*.$i" -delete
			done	
			echo -e "\n\033[33m_______Временные файлы удалены_______\033[37m\n"	
		elif [[ $n == "7" ]]; then
			echo "Выберите необходимый пункт:
1 -- Выполнить записанную команду
2 -- Изменить записанную команду"
			read -rp ": " number
			if [[ $number == "1" ]]; then #Выполнение записанной команды скрипта
				cur=$(pwd)
				cd "$work_folder" || exit
				eval "$cur_command"
				cd "$cur/" || exit
				echo -e "\n\033[33m_______Команда выполнена_______\033[37m\n"
			elif [[ $number == "2" ]]; then #Изменение записанной команды скрипта
				read -rp "Введите новую команду: " cur_command
				echo -e "\n\033[33m_______Команда изменена_______\033[37m\n"
			fi
		elif [[ $n == "8" ]]; then #Вывод числа строк и слов в каждом рабочем файле в рабочей папке
			for i in $ext_work; do
				str=$(ls "$work_folder" | grep \."$i")
				if [[ $str =~ .+ ]]; then
					for j in "$work_folder"*."$i"; do
						echo -e "\033[33mВ файле\033[37m $j\033[33m:\033[37m $(wc -l < "$j") \033[33mстрок и\033[37m $(wc -w < "$j") \033[33mслов\033[37m"
					done
				fi
			done
		elif [[ $n == "9" ]]; then #Вывод размера всех мусорных файлов в рабочей папке
			for i in $ext_temp; do
				str=$(ls "$work_folder" | grep \."$i")
				if [[ $str =~ .+ ]]; then
					for j in "$work_folder"*."$i"; do
						echo -e "\033[33mФайл\033[37m $j \033[33mимеет размер:\033[37m $(wc -c < "$j") \033[33mбайтов\033[37m"
					done
				fi
			done
		elif [[ $n == "0" ]]; then #Выход из скрипта
			echo -e "\n\033[31mВыберите желаемый пункт: 
1 -- Выйти из меню
2 -- Удалить файл с настройками скрипта и выйти из меню\033[37m"
			read -rp ": " number
			if [[ $number == "1" ]]; then
				exit
			elif [[ $number == "2" ]]; then
				rm "$script_folder"".myconfig"
				exit
			fi
		fi
	done
fi
