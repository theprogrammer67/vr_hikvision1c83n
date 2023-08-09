# MarkdownRenderer

## Markdown

[Markdown](https://ru.vikiansiklopedi.org/wiki/Markdown) — облегчённый язык разметки, созданный с целью написания наиболее читаемого и удобного для правки текста, но пригодного для преобразования в языки для продвинутых публикаций (HTML, Rich Text и других)

Как пишет сам автор Markdown Джон Грубер, идея языка в том, чтобы синтаксис был настолько прост, компактен и очевиден, что размеченный документ оставался бы полностью читаемым и непосвященный человек мог бы даже решить, что перед ним обычный plain text

Наиболее удобная бесплатная программа для создания и редактирования markdown-документов - [Typora](https://typora.io/) 

## Описание

Библиотека *MarkdownRenderer* предназначена для максимально простого и быстрого добавления справочной информации или другой документации в любой проект Delphi. Она позволяет с помощью одной команды визуализировать любой документ, созданный в формате Markdown.

Библиотека поддерживает как стандартный минимальный диалект так и его популярную расширенную версию **GFM** ([GitHub Flavored Markdown](https://github.github.com/gfm/))

Библиотека содержит тестовый проект, демонстрирующий её работу

## Использование

1. Для использования библиотеки нужно выполнить несколько простейших шагов:
2. Подключить к проекту репозиторий MarkdownRenderer
3. Создать zip-архив документа, содержащий:
   - Файл документа с расширением *.md
   - Файл стилей с расширением *.css (не обязательно)
   - Файлы изображений, включенных в документ (если необходимо)
4. Добавить созданный архив в ресурсы проекта
5. Вызвать в нужном месте кода команду рендеринга *TMarkdownRenderer.Render*

## Пример

```
uses
  uMarkdownRenderer, ...;

...

procedure TfrmMain.btnShowMarkdownClick(Sender: TObject);
var
  LSourceName, LCaption: string;
begin
  LSourceName := 'md';
  LCaption := 'Markdown документ';
	
  if TMarkdownRenderer.SourceExist(LSourceName) then
    TMarkdownRenderer.Render(LSourceName, LCaption);
end;
```
