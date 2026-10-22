# Heathcliff controls reference

This reference lists the workbench buttons, item menus, dialogs, and
preferences. See the Users Guide for workflows and Keyboard Shortcuts for
the editor's key combinations. Changes require an authenticated ship session.

## Toolbar

| Control | Action |
| --- | --- |
| Upload… | Open the upload destination picker. Choose a desk, destination path, and local file or folder. |
| Settings (gear) | Open theme, keybinding, screen format, and upload preferences. |
| Help | List Keyboard Shortcuts, Users Guide, Reference, and About Heathcliff and Ace editor. A topic opens a remembered documentation tab. A built-in guide appears when `/docs` is unavailable. |

## Panes and tabs

| Control | Action |
| --- | --- |
| Apps tab | Browse every desk's complete file tree. |
| Data tab | Browse each desk's `/data` tree. A sole folder named for its desk is flattened in this view. |
| Desk/folder disclosure arrow or name | Expand or collapse its children. |
| File name | Select the file; double-click to open it. Drag it into the reference pane to open its attributes. |
| Item … button | Open the item's context menu. Right-click, Shift+F10, or the context-menu key opens the same menu. |
| Source file tab | Select an open document and its result preview. Drag tabs to reorder them. |
| Source tab close (×, or ● for unsaved changes) | Close that document; confirm discarding unsaved changes when asked. |
| Attributes/Permissions reference tab | Select that item's information at its saved revision. Double-click a file reference tab to open the file. Drag tabs to reorder them. |
| Reference/documentation tab close (×) | Close the reference or documentation tab. |
| Documentation tab | Select its help page. |
| Pane collapse/expand arrow | Hide or restore the associated pane or band. |
| Fullscreen icon | Expand the associated pane to fullscreen; use the icon again or Escape to leave. |
| Pane divider | Drag to resize adjacent panes. |

## Source and result

| Control | Action |
| --- | --- |
| Download… | Immediately left of Save. Download the active file at its selected revision. Disabled for a draft with no saved path. Downloads committed content, not unsaved editor changes. |
| + (New file tab) | Open a new empty draft, preserving other tabs. Located at the end of the file tabs. |
| Save | Save the active editable file, including an empty draft. For drafts, browse desk trees to build a destination path, then type any new folders and `name.mark`. Saving historical text asks to create a current version. Disabled when the active file is read-only. |
| Save As… | Choose a destination and save the active file there. Located immediately right of Save, with the same enable/disable rules. |
| Copy | Copy the source text to the clipboard. |
| Result tree disclosure arrow | Expand or collapse JSON/XML nodes. |
| Download in a preview | Download the committed file when a preview offers this fallback. |
| Audio/video controls | Browser-provided playback, seeking, volume, and other supported media controls. |
| PDF controls | Browser-provided PDF navigation, zoom, download, and printing, where supported. |

Result previews of edited text use the unsaved buffer; binary previews use
the stored file. The editor's command palette (F1) lists available commands:
type to filter and select a command to run it. See Keyboard Shortcuts for
the editor's bindings.

### Editor search and replace

Open Find or Replace using the shortcuts in Keyboard Shortcuts.

| Control | Action |
| --- | --- |
| Search for | Enter the text or regular expression to find. |
| Previous / Next arrows | Move to the previous or next match. |
| All beside Search for | Select all matching occurrences. |
| + (Toggle Replace mode) | Show or hide the replacement row. |
| Replace with | Enter replacement text. |
| Replace | Replace the selected match and find the next one. |
| All beside Replace with | Replace all matches. |
| `.*` | Toggle regular-expression searching. |
| Aa | Toggle case-sensitive searching. |
| `\b` | Toggle whole-word searching. |
| S | Restrict searching to the current selection. |
| Search close (×) | Close the search panel; Escape also closes it. |

Replacement changes the editor buffer; Save commits those edits. A
read-only file can be searched but cannot be edited. The editor's ordinary
right-click text menu is provided by the browser; file actions belong to
the Explorer item menu below.

## Desk revision controls

| Control | Action |
| --- | --- |
| Revision box (`now N` or a number) | Type a desk revision from 1 through its current head, or `now`. |
| ▾ / Down arrow | Step to an older revision. |
| ▴ / Up arrow | Step to a newer revision; reaching the head returns to now. |
| Revision dialog: Browse | Validate the entered revision and browse it. An invalid number leaves the dialog open with the valid range. |
| Revision dialog: Cancel | Close without changing the selected revision. |

Each desk and each Apps/Data view keeps its own revision selection.

## Item context menu

| Item | Available on | Action |
| --- | --- | --- |
| Open | Files | Open the selected revision in Source and Result. Disabled for tombstoned content. |
| Download… | Files | Download the selected revision's committed file. Disabled for tombstoned content. |
| Download… | Desks and folders | Choose a local folder and download the selected tree's contents, preserving nested folders. Current trees are pinned to one revision; historical trees use the selected revision. Tombstoned files are skipped and counted. |
| Attributes… | Desks, folders, files | Open an information tab with identity, revision, path, file size/type, and available media metadata. Tombstoned files still have attributes. |
| Permissions… | Desks, folders, files | Open the read/write rules and ship-wide crews. Historical selections show current permissions read-only. |
| Upload… | Current desks and folders | Open the upload requestor with its destination frozen. Choose a local file or folder. Apps uses the configured upload prefix; Data uses its selected directory. |
| Delete | Current files | Confirm a new desk revision that omits this file. Other files and earlier revisions remain. Open current-file tabs become unsaved drafts after success. Text, binary, and unknown-mark files can be deleted. |
| Delete | Current desks and partial paths | Confirm recursive deletion of the listed files, including all subpaths. Files that fail preflight are left as is; eligible files are deleted together in one new revision. No eligible files means no new revision. A failed commit deletes none of its files. |
| Tombstone | Files at prior revisions | Confirm permanent disposal of the historical content. Disabled if already tombstoned. Refused if the version matches the current file, or if any current desk/path still uses that content. |
| Tombstone | Desks and partial paths at prior revisions | Confirm recursive tombstoning of the selected revision's files. Already-tombstoned content is skipped; current-content protections still apply. Processing continues past failures; files that cannot be tombstoned are left as is. |
| Now | Desks, folders, files | Return this item's desk to its current revision. Disabled when already current or when the desk has only one revision. |
| Revision… | Desks, folders, files | Choose a revision of this item's desk. Disabled when it has only one revision. |

Delete commits a change and advances the desk revision number only after
Clay confirms it. If the file is missing, the request is refused. A failed
or cancelled operation does not convert open tabs to drafts.

Tombstone does not change any revision's file listing or advance the
revision number. Clay shares identical stored content: every historical
path/revision using that content becomes tombstoned. This cannot be undone.
Deleting the current file can make its historical content eligible, but
other current references still prevent tombstoning.

Partial-path confirmations warn that the operation may be partially
successful. The file list is captured before confirmation; newly added paths
are not included. Cancel changes nothing. Delete uses one batch commit;
Tombstone attempts each file separately,
with successful changes retained even if another file fails. The final
message lists confirmed successes, failures/unconfirmed requests, and
already-tombstoned files, with per-file error details. Connection or
verification errors can leave an outcome uncertain: check those files before
retrying. Only successfully deleted current-file tabs become drafts;
failed-file tabs and historical tabs retain their paths. Only one partial-path
Delete/Tombstone operation can run at a time.

## Confirmation and file dialogs

| Control | Action |
| --- | --- |
| Delete confirmation: OK | Commit the deletion described above. |
| Tombstone confirmation: Tombstone | Request permanent disposal of the selected historical content. |
| Confirmation: Cancel | Leave the operation unapplied. |
| Historical save: OK | Save the edited text as the current file; the tab switches to now. |
| Overwrite confirmation: OK | Replace an existing file, including one changed since it was loaded. |
| Discard confirmation: OK | Discard unsaved changes for the pending close/open action. |
| File dialog: path and Save | Choose the draft's destination and submit it. |
| File dialog: destination tree | Expand current desk trees; selecting a desk or folder fills a partial path, and selecting a file fills its complete path. Append new folders and a filename in the path field. |
| File dialog: Cancel | Keep the draft unsaved. |
| Notification close (×) | Dismiss the message. Errors may remain visible until dismissed. |

Escape closes dismissible dialogs and menus. Confirmation dialogs start
with Cancel focused. Errors are reported rather than treated as success.

## Upload dialog

| Control | Action |
| --- | --- |
| Destination path | In the toolbar requestor, enter `/desk/folder/name.mark` or `/desk/folder/name/mark` for a file, or `/desk/folder/` for a folder's contents. Frozen to the selected partial path in the context-menu requestor. Uploads always target now. |
| Destination tree | Expand desks/folders or select a file to fill the path. New folders and names can be typed. Hidden when the destination is frozen. |
| Choose file… | Select a local file. The toolbar picker can rename it through the destination; item-menu uploads keep its local filename. |
| Choose folder… | Select all files in a local folder and its subfolders. Use a partial destination path. The chosen folder's contents are appended there, retaining subfolder paths but omitting the chosen root folder's name. Empty folders are omitted. |
| Replace the existing file | Authorize overwriting an existing destination. |
| Install these marks | Authorize copying missing mark sources and dependencies from the listed desks, in the same commit as the upload. Existing marks are not replaced. |
| Upload | Submit after destination, format, size, replacement, and mark checks pass. Disabled while checks fail or submission is pending. |
| Folder replacement / mark checkboxes | Authorize replacing listed existing files and installing listed missing marks. Each file is committed separately; a failure stops the batch without undoing completed uploads. |
| Cancel | Close the dialog and stop subsequent files in a folder upload. An upload already sent may still finish; completed files remain. |

Upload names are lowercased, with characters other than `a-z`, `0-9`, and
`-` replaced by `-`; the final dot separates the mark. This includes typed
filenames and local subfolder names. `.sh` is editable text, like `.txt`;
`.heic` is read-only image data, like `.png`.

## Folder download

| Control | Action |
| --- | --- |
| Browser folder chooser | Select the local destination and grant write access. Requires directory-picker support over HTTPS or localhost. Cancel leaves local files unchanged. |
| Automatic ZIP fallback | When the directory picker is unavailable (including ordinary HTTP), download the tree as a ZIP with its subfolders preserved. Extract it into your chosen destination. The browser's usual download settings control where the ZIP is saved. |
| Local overwrite: OK | Replace the named existing local file, then continue the download. |
| Local overwrite: Cancel | Stop the batch without replacing that file. Previously downloaded files remain. |

Files go directly into the chosen folder; the selected partial path's root
name is omitted, and nested paths become subfolders. Each file uses its
mark's external bytes and filename, just like a single-file download
(`noun` downloads as `.jam`, for example). A failure stops subsequent files
and reports the completed count; earlier downloads remain. Duplicate local
destinations are reported, not silently overwritten. Empty folders are not
represented in Clay. Only one folder download runs at a time.

ZIP fallback uses the same revision, filenames, bytes, tombstone filtering,
and duplicate-path checks. It stores files without compression, builds the
archive in the browser, and limits it to 256 MiB and 65,534 files. An error
discards the prepared archive; no partial ZIP is downloaded. Progress and
completion messages are green; errors retain error styling. Denying or
cancelling an available folder picker does not start a ZIP fallback.

## Permissions tab

These edits are offered only for a current selection. Rules shown for an
older revision are today's rules: Clay does not keep permission history.

| Control | Action |
| --- | --- |
| Read/write mode | Select whitelist (only the listed ships/crews) or blacklist (everyone except those listed). |
| Ships / Crews | Enter the rule's members. Named crews must exist. |
| Set read here / Set write here | Store the chosen rule on the selected path. |
| Clear: inherit from parent | Remove the explicit rule on this path so its parent/default applies. |
| Crew name / members | Enter a crew to create or replace. Crews are ship-wide. |
| Save crew | Create or update the crew. |
| Crew Delete | Confirm removal of that crew and its references in rules. Removing it from a blacklist can admit more ships. This is separate from file Delete. |
| Reload crews from clay | Refresh crews, including changes made outside Heathcliff. |

Write rules are stored but not enforced by this kernel. The explicit-rule
listing searches up to 512 paths with files; it reports truncation and
cannot discover rules on empty paths.

## Settings

| Control | Choices and effect |
| --- | --- |
| Theme | System, Light, or Dark. System follows the browser's color preference. |
| Keybindings | Ace or Vim editor keybindings. |
| Screen format | Columns: reference, editor, and result side by side. Rows: reference beside editor stacked above result. |
| Apps uploads | `/data/` (default) or `/`. Applies to Apps item uploads and the toolbar destination tree. Data item uploads stay in the selected Data directory. |
| Close settings / Close Help (×) | Close the corresponding panel. |

Preferences and workbench state are remembered in this browser.
