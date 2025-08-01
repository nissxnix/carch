use crossterm::event::{KeyCode, KeyEvent, MouseEvent, MouseEventKind};
use log::info;

use super::popups::run_script::RunScriptPopup;
use super::state::{App, AppMode, FocusedPanel};

impl<'a> App<'a> {
    pub fn handle_search_input(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Esc => self.toggle_search_mode(),
            KeyCode::Enter => {
                if !self.search.results.is_empty() {
                    let selected_item = self.search.results[self.search.selected_idx].clone();
                    if self.log_mode {
                        info!(
                            "Selected script from search: {}/{}",
                            selected_item.item.category, selected_item.item.name
                        );
                    }

                    if let Some(category_idx) =
                        self.categories.items.iter().position(|c| *c == selected_item.item.category)
                    {
                        self.categories.state.select(Some(category_idx));
                        self.update_script_list();

                        if let Some(script_idx) = self
                            .scripts
                            .items
                            .iter()
                            .position(|s| s.name == selected_item.item.name)
                        {
                            self.scripts.state.select(Some(script_idx));
                        }
                    }

                    self.update_preview();
                    self.toggle_search_mode();
                    self.focused_panel = FocusedPanel::Scripts;
                    self.mode = AppMode::Normal;
                }
            }
            KeyCode::Down => {
                if !self.search.results.is_empty() {
                    self.search.selected_idx =
                        (self.search.selected_idx + 1) % self.search.results.len();
                }
            }
            KeyCode::Up => {
                if !self.search.results.is_empty() {
                    self.search.selected_idx = if self.search.selected_idx > 0 {
                        self.search.selected_idx - 1
                    } else {
                        self.search.results.len() - 1
                    };
                }
            }
            KeyCode::Tab => {
                if let Some(autocomplete) = self.search.autocomplete.take() {
                    self.search.input = autocomplete;
                    self.search.cursor_position = self.search.input.len();
                    self.perform_search();
                    self.update_autocomplete();
                }
            }
            KeyCode::Char(c) => {
                self.search.input.push(c);
                self.search.cursor_position += 1;
                self.perform_search();
                self.update_autocomplete();
                self.search.selected_idx = 0;
            }
            KeyCode::Backspace => {
                if self.search.cursor_position > 0 {
                    self.search.input.remove(self.search.cursor_position - 1);
                    self.search.cursor_position -= 1;
                    self.perform_search();
                    self.update_autocomplete();
                    self.search.selected_idx = 0;
                }
            }
            KeyCode::Left => {
                if self.search.cursor_position > 0 {
                    self.search.cursor_position -= 1;
                }
                self.search.autocomplete = None;
            }
            KeyCode::Right => {
                if self.search.cursor_position < self.search.input.len() {
                    self.search.cursor_position += 1;
                }
                if self.search.cursor_position == self.search.input.len()
                    && self.search.autocomplete.is_some()
                {
                    self.search.input = self.search.autocomplete.take().unwrap();
                    self.search.cursor_position = self.search.input.len();
                    self.perform_search();
                }
            }
            _ => {}
        }
    }

    pub fn handle_key_normal_mode(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Char('q') => {
                if self.multi_select.enabled {
                    self.toggle_multi_select_mode();
                } else {
                    self.quit = true;
                }
            }
            KeyCode::Esc => {
                if self.multi_select.enabled {
                    self.toggle_multi_select_mode();
                }
            }
            KeyCode::Char('j') | KeyCode::Down => {
                self.next();
            }
            KeyCode::Char('k') | KeyCode::Up => {
                self.previous();
            }
            KeyCode::Char('h') | KeyCode::Left => {
                self.focused_panel = FocusedPanel::Categories;
                self.scripts.state.select(None);
            }
            KeyCode::Char('l') | KeyCode::Right => {
                if self.focused_panel == FocusedPanel::Scripts {
                    if self.scripts.state.selected().is_some()
                        && !(self.multi_select.enabled && self.multi_select.scripts.is_empty())
                    {
                        self.mode = AppMode::Confirm;
                    }
                } else {
                    self.focused_panel = FocusedPanel::Scripts;
                    if !self.scripts.items.is_empty() {
                        self.scripts.state.select(Some(0));
                    }
                }
            }
            KeyCode::Home => {
                self.top();
            }
            KeyCode::End => {
                self.bottom();
            }
            KeyCode::Char('/') => {
                self.toggle_search_mode();
            }
            KeyCode::Char('p') => {
                self.toggle_preview_mode();
            }
            KeyCode::Char('m') => {
                self.toggle_multi_select_mode();
            }
            KeyCode::Char('?') => {
                self.toggle_help_mode();
            }
            KeyCode::Char('d') => {
                self.toggle_description_popup();
            }
            KeyCode::Char('t') => {
                if !self.theme_locked {
                    self.cycle_theme();
                }
            }
            KeyCode::Enter => {
                if self.focused_panel == FocusedPanel::Scripts
                    && self.scripts.state.selected().is_some()
                    && !(self.multi_select.enabled && self.multi_select.scripts.is_empty())
                {
                    self.mode = AppMode::Confirm;
                }
            }
            KeyCode::Char(' ') => {
                if self.multi_select.enabled {
                    self.toggle_script_selection();
                }
            }
            _ => {}
        }
    }

    pub fn handle_key_preview_mode(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Char('q') | KeyCode::Esc | KeyCode::Char('p') | KeyCode::Char('h') => {
                self.mode = AppMode::Normal;
            }
            KeyCode::Char('j') | KeyCode::Down => {
                self.scroll_preview_down();
            }
            KeyCode::Char('k') | KeyCode::Up => {
                self.scroll_preview_up();
            }
            KeyCode::PageDown => {
                self.scroll_preview_page_down();
            }
            KeyCode::PageUp => {
                self.scroll_preview_page_up();
            }
            KeyCode::Home => {
                self.preview.scroll = 0;
            }
            KeyCode::End => {
                self.preview.scroll = self.preview.max_scroll;
            }
            _ => {}
        }
    }

    pub fn handle_mouse(&mut self, event: MouseEvent) {
        match event.kind {
            MouseEventKind::ScrollDown => match self.mode {
                AppMode::Normal => self.next(),
                AppMode::Preview => {
                    for _ in 0..2 {
                        self.scroll_preview_down();
                    }
                }
                AppMode::Search => {
                    // allows scrolling down through search results
                    if !self.search.results.is_empty() {
                        self.search.selected_idx =
                            (self.search.selected_idx + 1) % self.search.results.len();
                    }
                }
                AppMode::Confirm => {}
                AppMode::Help => {
                    // ensures scrolling doesn't go past the bottom of the help text
                    self.help.scroll = self.help.scroll.saturating_add(2).min(self.help.max_scroll);
                }
                AppMode::Description => {}
                AppMode::RunScript => {}
                AppMode::RootWarning => {}
            },
            MouseEventKind::ScrollUp => match self.mode {
                AppMode::Normal => self.previous(),
                AppMode::Preview => {
                    for _ in 0..2 {
                        self.scroll_preview_up();
                    }
                }
                AppMode::Search => {
                    // allows scrolling up through search results
                    if !self.search.results.is_empty() {
                        self.search.selected_idx = if self.search.selected_idx > 0 {
                            self.search.selected_idx - 1
                        } else {
                            self.search.results.len() - 1
                        };
                    }
                }
                AppMode::Confirm => {}
                AppMode::Help => {
                    self.help.scroll = self.help.scroll.saturating_sub(2);
                }
                AppMode::Description => {}
                AppMode::RunScript => {}
                AppMode::RootWarning => {}
            },
            _ => {}
        }
    }

    pub fn handle_key_confirmation_mode(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Char('y') | KeyCode::Char('Y') | KeyCode::Char('l') | KeyCode::Right => {
                if self.log_mode {
                    if self.multi_select.enabled && !self.multi_select.scripts.is_empty() {
                        info!(
                            "Confirmed execution of {} scripts.",
                            self.multi_select.scripts.len()
                        );
                    } else if let Some(script_path) = self.get_script_path() {
                        info!("Confirmed execution of script: {}", script_path.display());
                    }
                }

                if self.multi_select.enabled && !self.multi_select.scripts.is_empty() {
                    self.script_execution_queue = self.multi_select.scripts.clone();
                } else if let Some(script_path) = self.get_script_path() {
                    self.script_execution_queue.push(script_path);
                }

                if !self.script_execution_queue.is_empty() {
                    let script_path = self.script_execution_queue.remove(0);
                    let popup = RunScriptPopup::new(script_path, self.log_mode, self.theme.clone());
                    self.run_script_popup = Some(popup);
                    self.mode = AppMode::RunScript;
                } else {
                    self.mode = AppMode::Normal;
                }
            }
            KeyCode::Char('n')
            | KeyCode::Char('N')
            | KeyCode::Esc
            | KeyCode::Char('h')
            | KeyCode::Char('q')
            | KeyCode::Left => {
                if self.log_mode {
                    info!("Cancelled script execution.");
                }
                self.mode = AppMode::Normal;
            }
            _ => {}
        }
    }

    pub fn handle_key_help_mode(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Esc | KeyCode::Char('q') | KeyCode::Char('?') => {
                self.mode = AppMode::Normal;
                self.help.scroll = 0;
            }
            KeyCode::Char('j') | KeyCode::Down => {
                self.help.scroll = (self.help.scroll + 1).min(self.help.max_scroll);
            }
            KeyCode::Char('k') | KeyCode::Up => {
                self.help.scroll = self.help.scroll.saturating_sub(1);
            }
            KeyCode::Home => {
                self.help.scroll = 0;
            }
            KeyCode::End => {
                self.help.scroll = self.help.max_scroll;
            }
            KeyCode::PageDown => {
                self.help.scroll = (self.help.scroll + 10).min(self.help.max_scroll);
            }
            KeyCode::PageUp => {
                self.help.scroll = self.help.scroll.saturating_sub(10);
            }
            _ => {}
        }
    }

    pub fn handle_key_description_mode(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Esc | KeyCode::Char('q') | KeyCode::Char('d') => {
                self.mode = AppMode::Normal;
                self.description.content = None;
                self.description.scroll = 0;
            }
            KeyCode::Char('j') | KeyCode::Down => {
                self.description.scroll =
                    (self.description.scroll + 1).min(self.description.max_scroll);
            }
            KeyCode::Char('k') | KeyCode::Up => {
                self.description.scroll = self.description.scroll.saturating_sub(1);
            }
            _ => {}
        }
    }
}
