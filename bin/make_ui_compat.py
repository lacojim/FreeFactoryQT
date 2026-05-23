#!/usr/bin/env python3
# USAGE: python3 make_ui_compat.py FreeFactory-tabs.ui FreeFactory-tabs-compat.ui

from pathlib import Path
import sys

REPLACEMENTS = {
    "Qt::LayoutDirection::": "Qt::",
    "Qt::Orientation::": "Qt::",
    "Qt::AlignmentFlag::": "Qt::",
    "Qt::ArrowType::": "Qt::",
    "Qt::InputMethodHint::": "Qt::",

    "QAbstractItemView::EditTrigger::": "QAbstractItemView::",
    "QComboBox::InsertPolicy::": "QComboBox::",
    "QFrame::Shape::": "QFrame::",
    "QFrame::Shadow::": "QFrame::",
    "QPlainTextEdit::LineWrapMode::": "QPlainTextEdit::",
    "QLineEdit::EchoMode::": "QLineEdit::",
    "QAbstractSpinBox::ButtonSymbols::": "QAbstractSpinBox::",
}

def convert_ui(input_file: Path, output_file: Path):
    text = input_file.read_text(encoding="utf-8")

    for old, new in REPLACEMENTS.items():
        text = text.replace(old, new)

    output_file.write_text(text, encoding="utf-8")
    print(f"Wrote compatibility UI: {output_file}")

def main():
    if len(sys.argv) != 3:
        print("Usage: make_ui_compat.py INPUT.ui OUTPUT.ui")
        sys.exit(1)

    convert_ui(Path(sys.argv[1]), Path(sys.argv[2]))

if __name__ == "__main__":
    main()
