-- Maximise ordinary application windows. Dialogs, docks and the Rofi
-- launcher are left alone.
if (get_window_type() == "WINDOW_TYPE_NORMAL") then
  maximize_vertically();
  maximize_horizontally();
end
