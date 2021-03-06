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


/**
 * Describes everything a timeline should provide, in an abstract way.
 * Default implementations are given through the *_internal methods.
 */
public interface ITimeline : Gtk.Widget, IPage {
  public static const int REST = 25;
  /** The lowest id of any tweet in this timeline */
  protected abstract int64 lowest_id            {get; set;}
  protected abstract int64 max_id               {get; set; default = 0;}
  protected abstract TweetListBox tweet_list    {get; set;}
  public    abstract int unread_count           {get; set;}
  public    abstract DeltaUpdater delta_updater {get; set;}
  protected abstract string function            {get;}


  /**
   * Default implementation for loading the newest tweets
   * from the given function of the twitter api.
   *
   * @param function The twitter function to use
   */
  protected async void load_newest_internal () { //{{{
    var call = account.proxy.new_call ();
    call.set_function (this.function);
    call.set_method("GET");
    call.add_param ("count", "28");
    call.add_param ("contributor_details", "true");
    call.add_param ("include_my_retweet", "true");
    call.add_param ("max_id", (lowest_id - 1).to_string ());

    try {
      yield call.invoke_async (null);
    } catch (GLib.Error e) {
      if (call.get_payload () != null) {
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE);
      } else {
        tweet_list.set_placeholder_text (e.message);
      }
      tweet_list.set_empty ();
      return;
    }

    var parser = new Json.Parser ();
    try {
      parser.load_from_data (call.get_payload ());
    } catch(GLib.Error e) {
      critical (e.message);
      return;
    }

    var root = parser.get_root().get_array();
    if (root.get_length () == 0) {
      tweet_list.set_empty ();
      return;
    }
    var res = yield TweetUtils.work_array (root, delta_updater, tweet_list, main_window, account);

    if (res.min_id < this.lowest_id)
      this.lowest_id = res.min_id;

    if (res.max_id > this.max_id)
      this.max_id = res.max_id;
  } //}}}

  /**
   * Default implementation to load older tweets.
   *
   * @param function The Twitter function to use
   * @param tweet_type The type of tweets to load
   */
  protected async void load_older_internal () { //{{{
    var call = account.proxy.new_call ();
    call.set_function (this.function);
    call.set_method ("GET");
    call.add_param ("count", "28");
    call.add_param ("include_my_retweet", "true");
    call.add_param ("max_id", (lowest_id - 1).to_string ());
    try {
      yield call.invoke_async (null);
    } catch (GLib.Error e) {
      Utils.show_error_object (call.get_payload (), e.message,
                               GLib.Log.LINE, GLib.Log.FILE);
      return;
    }
    var parser = new Json.Parser();
    try {
      parser.load_from_data (call.get_payload ());
    } catch (GLib.Error e) {
      critical(e.message);
      return;
    }
    var root = parser.get_root ().get_array ();
    if (root.get_length () == 0) {
      tweet_list.set_empty ();
      return;
    }
    var res = yield TweetUtils.work_array (root, delta_updater, tweet_list, main_window, account);
    if (res.min_id < lowest_id)
      lowest_id = res.min_id;
  } ///}}}

  /**
   * Mark the TweetListEntries the user has already seen.
   *
   * @param value The scrolling value as from Gtk.Adjustment
   */
  protected void mark_seen_on_scroll (double value) { //{{{
    if (unread_count == 0)
      return;

    tweet_list.forall_internal (false, (w) => {
      ITwitterItem tle = (ITwitterItem)w;
      if (tle.seen)
        return;

      Gtk.Allocation alloc;
      tle.get_allocation(out alloc);
      if (alloc.y+(alloc.height/2.0) >= value) {
        tle.seen = true;
        unread_count--;
      }

    });
  } //}}}


}
