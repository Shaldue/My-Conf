﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ПрограммныйИнтерфейс
	
#Область ДляВызоваИзДругихПодсистем

// СтандартныеПодсистемы.ГрупповоеИзменениеОбъектов

// Возвращает реквизиты объекта, которые разрешается редактировать
// с помощью обработки группового изменения реквизитов.
//
// Возвращаемое значение:
//  Массив из Строка
//
Функция РеквизитыРедактируемыеВГрупповойОбработке() Экспорт
	
	РедактируемыеРеквизиты = Новый Массив;
	РедактируемыеРеквизиты.Добавить("Используется");
	
	Возврат РедактируемыеРеквизиты;
	
КонецФункции

// Конец СтандартныеПодсистемы.ГрупповоеИзменениеОбъектов

// Регистрирует на плане обмена ОбновлениеИнформационнойБазы объекты,
// которые необходимо обновить на новую версию.
//
// Параметры:
//  Параметры - Структура - служебный параметр для передачи в процедуру ОбновлениеИнформационнойБазы.ОтметитьКОбработке.
//
Процедура ЗарегистрироватьДанныеКОбработкеДляПереходаНаНовуюВерсию(Параметры) Экспорт
	
	ТекстЗапроса =
	"ВЫБРАТЬ
	|	МакетыПечатныхФорм.Ссылка
	|ИЗ
	|	Справочник.МакетыПечатныхФорм КАК МакетыПечатныхФорм
	|ГДЕ
	|	МакетыПечатныхФорм.ИсточникДанных <> НЕОПРЕДЕЛЕНО";
	
	Запрос = Новый Запрос(ТекстЗапроса);
	Макеты = Запрос.Выполнить().Выгрузить().ВыгрузитьКолонку("Ссылка");

	ДополнительныеПараметры = ОбновлениеИнформационнойБазы.ДополнительныеПараметрыОтметкиОбработки();
	ОбновлениеИнформационнойБазы.ОтметитьКОбработке(Параметры, Макеты, ДополнительныеПараметры);
	
КонецПроцедуры

#КонецОбласти

#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

// Параметры:
//  Макет - УникальныйИдентификатор
//  
// Возвращаемое значение:
//  Массив из Строка
// 
Функция ЯзыкиМакета(Макет) Экспорт 
	
	ТекстЗапроса = 
	"ВЫБРАТЬ
	|	МакетыПечатныхФорм.Макет КАК Макет,
	|	&КодОсновногоЯзыка КАК КодЯзыка
	|ИЗ
	|	Справочник.МакетыПечатныхФорм КАК МакетыПечатныхФорм
	|ГДЕ
	|	МакетыПечатныхФорм.Идентификатор = &Идентификатор
	|
	|ОБЪЕДИНИТЬ ВСЕ
	|
	|ВЫБРАТЬ
	|	МакетыПечатныхФормПредставления.Макет,
	|	МакетыПечатныхФормПредставления.КодЯзыка
	|ИЗ
	|	Справочник.МакетыПечатныхФорм.Представления КАК МакетыПечатныхФормПредставления
	|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.МакетыПечатныхФорм КАК МакетыПечатныхФорм
	|		ПО МакетыПечатныхФормПредставления.Ссылка = МакетыПечатныхФорм.Ссылка
	|ГДЕ
	|	МакетыПечатныхФорм.Идентификатор = &Идентификатор";
	
	Запрос = Новый Запрос(ТекстЗапроса);
	Запрос.УстановитьПараметр("Идентификатор", Макет);
	Запрос.УстановитьПараметр("КодОсновногоЯзыка", ОбщегоНазначения.КодОсновногоЯзыка());
	
	Результат = Новый Массив;

	Выборка = Запрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() Цикл
		Если Выборка.Макет.Получить() <> Неопределено Тогда
			Результат.Добавить(Выборка.КодЯзыка);
		КонецЕсли;
	КонецЦикла;
	
	Возврат Результат;
	
КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Процедура ОбработатьДанныеДляПереходаНаНовуюВерсию(Параметры) Экспорт
	
	ОбъектовОбработано = 0;
	ПроблемныхОбъектов = 0;
	
	Выборка = ОбновлениеИнформационнойБазы.ВыбратьСсылкиДляОбработки(Параметры.Очередь, "Справочник.МакетыПечатныхФорм");
	Пока Выборка.Следующий() Цикл
		Блокировка = Новый БлокировкаДанных;
		ЭлементБлокировки = Блокировка.Добавить("Справочник.МакетыПечатныхФорм");
		ЭлементБлокировки.УстановитьЗначение("Ссылка", Выборка.Ссылка);
		
		НачатьТранзакцию();
		Попытка
			Блокировка.Заблокировать();
			
			Макет = Выборка.Ссылка.ПолучитьОбъект(); // СправочникОбъект.МакетыПечатныхФорм
			СтрокаТаблицы = Макет.ИсточникиДанных.Добавить();
			СтрокаТаблицы.ИсточникДанных = Макет.ИсточникДанных;
			Макет.ИсточникДанных = Неопределено;
			ОбновлениеИнформационнойБазы.ЗаписатьДанные(Макет);
			ОбъектовОбработано = ОбъектовОбработано + 1;
			ЗафиксироватьТранзакцию();
		Исключение
			ОтменитьТранзакцию();
			ПроблемныхОбъектов = ПроблемныхОбъектов + 1;

			ТекстСообщения = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
				НСтр("ru = 'Не удалось обработать %1 по причине:
					 |%2'"), 
				Выборка.Ссылка, ОбработкаОшибок.ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
			ЗаписьЖурналаРегистрации(ОбновлениеИнформационнойБазы.СобытиеЖурналаРегистрации(),
				УровеньЖурналаРегистрации.Предупреждение, Метаданные.Справочники.МакетыПечатныхФорм,
				Выборка.Ссылка, ТекстСообщения);
		КонецПопытки;
	КонецЦикла;
	
	Параметры.ОбработкаЗавершена = ОбновлениеИнформационнойБазы.ОбработкаДанныхЗавершена(Параметры.Очередь, "РегистрСведений.ПользовательскиеМакетыПечати");
	
	Если ОбъектовОбработано = 0 И ПроблемныхОбъектов <> 0 Тогда
		ТекстСообщения = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
			НСтр("ru = 'Не удалось обработать некоторые макеты печати (пропущены): %1'"),
			ПроблемныхОбъектов);
		ВызватьИсключение ТекстСообщения;
	Иначе
		ЗаписьЖурналаРегистрации(ОбновлениеИнформационнойБазы.СобытиеЖурналаРегистрации(),
			УровеньЖурналаРегистрации.Информация, Метаданные.РегистрыСведений.ПользовательскиеМакетыПечати,,
				СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
					НСтр("ru = 'Обработана очередная порция макетов печати: %1'"),
			ОбъектовОбработано));
	КонецЕсли;
	
КонецПроцедуры

Функция ЗаписатьМакет(ОписаниеМакета) Экспорт
	
	Ссылка = ОписаниеМакета.Ссылка;
	Если ЗначениеЗаполнено(Ссылка) Тогда
		Объект = Ссылка.ПолучитьОбъект();
	Иначе
		Объект = СоздатьЭлемент();
		Объект.ТипМакета = ОписаниеМакета.ТипМакета;
		Объект.Идентификатор = Новый УникальныйИдентификатор;
	КонецЕсли;
	
	Объект.ИсточникиДанных.Очистить();
	Для Каждого ИсточникДанных Из ОписаниеМакета.ИсточникиДанных Цикл
		НоваяСтрока = Объект.ИсточникиДанных.Добавить();
		НоваяСтрока.ИсточникДанных = ИсточникДанных;
	КонецЦикла;
	
	Наименование = ОписаниеМакета.Наименование;
	КодЯзыка = ОписаниеМакета.КодЯзыка;
	Макет = Новый ХранилищеЗначения(ПолучитьИзВременногоХранилища(ОписаниеМакета.АдресМакетаВоВременномХранилище));

	ОбщегоНазначения.УстановитьЗначениеРеквизита(Объект, "Наименование", Наименование, КодЯзыка);
	ОбщегоНазначения.УстановитьЗначениеРеквизита(Объект, "Макет", Макет, КодЯзыка);
	
	Блокировка = Новый БлокировкаДанных;
	ЭлементБлокировки = Блокировка.Добавить("Справочник.МакетыПечатныхФорм");
	Если ЗначениеЗаполнено(Ссылка) Тогда
		ЭлементБлокировки.УстановитьЗначение("Ссылка", Ссылка);
	КонецЕсли;
	
	НачатьТранзакцию();
	Попытка
		Блокировка.Заблокировать();
		Объект.Записать();
		
		ЗафиксироватьТранзакцию();
	Исключение
		ОтменитьТранзакцию();
		ВызватьИсключение;
	КонецПопытки;
	
	Возврат "ПФ_" + Строка(Объект.Идентификатор);
	
КонецФункции

// Параметры:
//  Макет - СправочникСсылка.МакетыПечатныхФорм
//  Используется - Булево
//
Процедура УстановитьИспользованиеМакета(Макет, Используется) Экспорт
	
	Блокировка = Новый БлокировкаДанных;
	ЭлементБлокировки = Блокировка.Добавить("Справочник.МакетыПечатныхФорм");
	ЭлементБлокировки.УстановитьЗначение("Ссылка", Макет);
	
	НачатьТранзакцию();
	Попытка
		Блокировка.Заблокировать();
		
		Объект = Макет.ПолучитьОбъект();
		Объект.Используется = Используется;
		Объект.Записать();
		
		ЗафиксироватьТранзакцию();
	Исключение
		ОтменитьТранзакцию();
		ВызватьИсключение;
	КонецПопытки;
	
КонецПроцедуры

Функция МакетСуществует(Идентификатор) Экспорт
	
	ТекстЗапроса = 
	"ВЫБРАТЬ
	|	Ссылка 
	|ИЗ
	|	Справочник.МакетыПечатныхФорм КАК МакетыПечатныхФорм
	|ГДЕ
	|	МакетыПечатныхФорм.Идентификатор = &Идентификатор";
	
	Запрос = Новый Запрос(ТекстЗапроса);
	Запрос.УстановитьПараметр("Идентификатор", Идентификатор);

	Возврат Не Запрос.Выполнить().Пустой();

КонецФункции

Функция НайтиМакет(ПутьКМакету, КодЯзыка) Экспорт
	
	Идентификатор = ИдентификаторМакета(ПутьКМакету);
	Если Идентификатор <> Неопределено Тогда
		Возврат МакетПечатнойФормыПоИдентификатору(Идентификатор, КодЯзыка);
	КонецЕсли;
	
	Возврат Неопределено;
	
КонецФункции

Функция МакетПечатнойФормыПоИдентификатору(Идентификатор, КодЯзыка)
	
	ТекстЗапроса =
	"ВЫБРАТЬ
	|	МакетыПечатныхФормПредставления.Макет
	|ИЗ
	|	Справочник.МакетыПечатныхФорм.Представления КАК МакетыПечатныхФормПредставления
	|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.МакетыПечатныхФорм КАК МакетыПечатныхФорм
	|		ПО МакетыПечатныхФормПредставления.Ссылка = МакетыПечатныхФорм.Ссылка
	|ГДЕ
	|	МакетыПечатныхФорм.Идентификатор = &Идентификатор
	|	И МакетыПечатныхФормПредставления.КодЯзыка = &КодЯзыка
	|
	|ОБЪЕДИНИТЬ ВСЕ
	|
	|ВЫБРАТЬ
	|	МакетыПечатныхФорм.Макет
	|ИЗ
	|	Справочник.МакетыПечатныхФорм КАК МакетыПечатныхФорм
	|ГДЕ
	|	МакетыПечатныхФорм.Идентификатор = &Идентификатор";
	
	Запрос = Новый Запрос(ТекстЗапроса);
	Запрос.УстановитьПараметр("Идентификатор", Идентификатор);
	Запрос.УстановитьПараметр("КодЯзыка", КодЯзыка);
	
	Выборка = Запрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() Цикл
		Макет = Выборка.Макет.Получить(); // ХранилищеЗначения
		Если Макет = Неопределено Тогда
			Продолжить;
		КонецЕсли;
		Если ТипЗнч(Макет) <> Тип("ДвоичныеДанные") Тогда
			Макет.КодЯзыка = ОбщегоНазначения.КодОсновногоЯзыка();
		КонецЕсли;
		Возврат Макет;
	КонецЦикла;
	
	Возврат Неопределено;
	
КонецФункции

Функция ИдентификаторМакета(ПутьКМакету) Экспорт
	
	ЧастиПути = СтрРазделить(ПутьКМакету, ".", Истина);
	
	ИмяМакета = ЧастиПути[ЧастиПути.ВГраница()];
	Если СтрНачинаетсяС(ИмяМакета, "ПФ_") Тогда
		Идентификатор = Сред(ИмяМакета, 4);
		Если СтроковыеФункцииКлиентСервер.ЭтоУникальныйИдентификатор(Идентификатор) Тогда
			Возврат Новый УникальныйИдентификатор(Идентификатор);
		КонецЕсли;
	КонецЕсли;
	
	Возврат Неопределено;
	
КонецФункции

// Возвращаемое значение:
//  СправочникСсылка.МакетыПечатныхФорм
//
Функция СсылкаМакета(ПутьКМакету) Экспорт
	
	Идентификатор = ИдентификаторМакета(ПутьКМакету);
	Если Идентификатор = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	ТекстЗапроса =
	"ВЫБРАТЬ
	|	МакетыПечатныхФорм.Ссылка КАК Ссылка
	|ИЗ
	|	Справочник.МакетыПечатныхФорм КАК МакетыПечатныхФорм
	|ГДЕ
	|	МакетыПечатныхФорм.Идентификатор = &Идентификатор";
	
	Запрос = Новый Запрос(ТекстЗапроса);
	Запрос.УстановитьПараметр("Идентификатор", Идентификатор);
	Выборка = Запрос.Выполнить().Выбрать();
	Если Выборка.Следующий() Тогда
		Возврат Выборка.Ссылка;
	КонецЕсли;
	
	Возврат Неопределено;
	
КонецФункции

Процедура УдалитьМакет(Ссылка, КодЯзыка = Неопределено) Экспорт
	
	Объект = Ссылка.ПолучитьОбъект();
	Если КодЯзыка = Неопределено Или КодЯзыка = ОбщегоНазначения.КодОсновногоЯзыка() Тогда
		Объект.УстановитьПометкуУдаления(Истина);
	Иначе
		ОбщегоНазначения.УстановитьЗначениеРеквизита(Объект, "Макет", Новый ХранилищеЗначения(Неопределено), КодЯзыка);
	КонецЕсли;

	Блокировка = Новый БлокировкаДанных;
	ЭлементБлокировки = Блокировка.Добавить("Справочник.МакетыПечатныхФорм");
	ЭлементБлокировки.УстановитьЗначение("Ссылка", Ссылка);
	
	НачатьТранзакцию();
	Попытка
		Блокировка.Заблокировать();
		Объект.Записать();
		
		ЗафиксироватьТранзакцию();
	Исключение
		ОтменитьТранзакцию();
		ВызватьИсключение;
	КонецПопытки;

КонецПроцедуры

Функция ИсточникиДанныхМакета(ПутьКМакету) Экспорт

	Идентификатор = ИдентификаторМакета(ПутьКМакету);
	Если Идентификатор = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	ТекстЗапроса =
	"ВЫБРАТЬ
	|	МакетыПечатныхФормИсточникиДанных.ИсточникДанных КАК ИсточникДанных
	|ИЗ
	|	Справочник.МакетыПечатныхФорм.ИсточникиДанных КАК МакетыПечатныхФормИсточникиДанных
	|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.МакетыПечатныхФорм КАК МакетыПечатныхФорм
	|		ПО МакетыПечатныхФормИсточникиДанных.Ссылка = МакетыПечатныхФорм.Ссылка
	|ГДЕ
	|	МакетыПечатныхФорм.Идентификатор = &Идентификатор";
	
	Запрос = Новый Запрос(ТекстЗапроса);
	Запрос.УстановитьПараметр("Идентификатор", Идентификатор);

	ИсточникиДанныхМакета = Запрос.Выполнить().Выгрузить().ВыгрузитьКолонку("ИсточникДанных");
	
	Возврат ИсточникиДанныхМакета;

КонецФункции

Процедура ПриДобавленииОбработчиковОбновления(Обработчики) Экспорт

	Обработчик = Обработчики.Добавить();
	Обработчик.Процедура = "Справочники.МакетыПечатныхФорм.ОбработатьДанныеДляПереходаНаНовуюВерсию";
	Обработчик.Версия = "3.1.8.48";
	Обработчик.РежимВыполнения = "Отложенно";
	Обработчик.Идентификатор = Новый УникальныйИдентификатор("959d09e5-1dc3-4f32-833a-05ff17365e30");
	Обработчик.ПроцедураЗаполненияДанныхОбновления = "Справочники.МакетыПечатныхФорм.ЗарегистрироватьДанныеКОбработкеДляПереходаНаНовуюВерсию";
	Обработчик.ПроцедураПроверки = "ОбновлениеИнформационнойБазы.ДанныеОбновленыНаНовуюВерсиюПрограммы";
	Обработчик.Комментарий = НСтр("ru = 'Заполняет сведения об источниках данных печати для пользовательских печатных форм. До завершения обработки некоторые печатные формы могут быть недоступны.'");
	
	Читаемые = Новый Массив;
	Читаемые.Добавить(Метаданные.Справочники.МакетыПечатныхФорм.ПолноеИмя());
	Обработчик.ЧитаемыеОбъекты = СтрСоединить(Читаемые, ",");
	
	Изменяемые = Новый Массив;
	Изменяемые.Добавить(Метаданные.Справочники.МакетыПечатныхФорм.ПолноеИмя());
	Обработчик.ИзменяемыеОбъекты = СтрСоединить(Изменяемые, ",");
	
	Блокируемые = Новый Массив;
	Блокируемые.Добавить(Метаданные.Справочники.МакетыПечатныхФорм.ПолноеИмя());
	Обработчик.БлокируемыеОбъекты = СтрСоединить(Блокируемые, ",");

КонецПроцедуры

#КонецОбласти

#КонецЕсли