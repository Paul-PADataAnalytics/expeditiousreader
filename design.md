# Design

The application is a speed reader program.  It shows the individual words of an ebook one at a time at a speed defined by the user.  It aligns each word in the center of the screen for easy reading and shows longer words with a slight pause to allow for comprehension.  Speed reading mode stores the position of the text as each word is read so the user can pick up from the same place later. The speed reader includes a sentence-end pause feature that applies a double delay when starting a new sentence for better comprehension. Chapter and sentence navigation controls allow users to jump between sections, and a chapter indicator shows the current chapter number.

The application also allows for reading in a traditional format, displaying the full page of text with options to change font size, background color, and other reading preferences.  Traditional mode resembles a newspaper in which text is shown in configurable columns (1-3) with dynamic text fitting that fills the entire available screen height without scrolling or overflow. Clicking or tapping on the outside right moves one page forward and clicking or tapping on the left moves one page backwards.  At any point, the view can be switched between speed reading and traditional reading modes, this allows users to quickly skim through text and then slow down for more detailed reading when needed.  Every time a page is turned, the current position of the book is updated.  Text is reflowed by removing all line breaks and laid out in columns such that only the words that fit into the available space are shown as a page. There is no scrolling or overflow. This means there is a variable amount of words per page but a fixed number of lines that fills the entire column height. Column width, column gap, and line height are configurable. As each page is turned, the progress of the book is updated to the first word on the new page using word-position based tracking. The speed reader and traditional reader each have independent font size settings.

The application keeps a library of known documents, allowing users to easily access and manage their ebooks.  It tracks reading progress for each document, so users can pick up where they left off.  The library also supports categorization and searching of documents for easy organization.  The library has the ability to select multiple documents and delete them.  The library has a cover image for each book.  The library has a filter to search for a book by author and name.  The library also has the option to change the cover image for any detected image in the book in the event the wrong one, or none at all, are chosen. The library supports importing multiple books at once with progress tracking and detailed success/failure reporting.

The application is a dart flutter application

The application is usable as a desktop application on Windows, and Linux, as a web application, and as a mobile application on Android.  The application presents a simple programmatic interface to allow for integration into other application as an on-demand document reader.  All features work with all platforms.

The application supports common ebook formats such as PDF, EPUB, and plain text files.  It includes features for importing and exporting documents to and from the library.  It is extensible, allowing for plugins or extensions to add support for additional formats or features in the future.  the application filters out contents pages, and indexes and starts each book at chapter 1.

When a book is added to the library, all the text is stripped from the file and stored in a plain text format for easy processing.  Metadata on the book is collected and stored in JSON format.  Metadata includes author, title, publication date, ISBN, genre, page count, word count, chapter positions and chosen cover image. HTML entities are decoded during text extraction to ensure clean, readable text with proper character rendering.

## Components

The main components of the application are:
- Speed Reader Engine: Responsible for displaying words one at a time at the specified speed, handling word alignment, and managing pauses for longer words.
- Traditional Reader: Manages the display of full pages of text, including font size adjustments, background color changes, and other reading preferences.  This similar to a kindle experience.
- Document Library: Handles the storage, organization, and retrieval of ebooks, including tracking reading progress and supporting categorization and searching, deleting and changing the cover.
- User Interface: Provides the visual elements and controls for users to interact with the application, switch between reading modes, and manage their document library.
- File Import/Export: Manages the importing of ebooks into the library and exporting them out, supporting various formats.
- Platform Integration: Ensures the application runs smoothly on different platforms (desktop, web, mobile) and provides a programmatic interface for integration with other applications.
- Extensibility Framework: Allows for the addition of plugins or extensions to enhance functionality and support additional ebook formats in the future.

## UI

Modes:
- Library
- Settings
- Speed Read
- Traditional Read
