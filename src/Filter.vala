/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2013 Timm Bäder
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */
public class Filter : GLib.Object {
  public int block_count  { get; set; }
  public string content   { get; set; }
  public int id           { get; set; }

  private GLib.Regex regex;

  public Filter (string expression) {
    this.content = expression;
    try {
      this.regex = new GLib.Regex (expression);
    } catch (GLib.RegexError e) {
      warning ("Regex error for `%s`: %s", expression, e.message);
    }
  }

  /**
   * (Re)Set the Filter's regular expression to the given one.
   *
   * @param expression The new expression.
   */
  public void reset (string expression) {
    try {
      this.regex = new GLib.Regex (expression);
    } catch (GLib.RegexError e) {
      warning ("Regex error for `%s`: %s", expression, e.message);
    }
    this.content = expression;
  }

  public bool matches (string test_text) {
    if (regex == null) {
      return false;
    }
    return regex.match (test_text);
  }
}
