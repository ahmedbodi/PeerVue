' SPDX-FileCopyrightText: 2020 Tod Fitch <tod@fitchfamily.org>
'
' SPDX-License-Identifier: MIT

sub init()
    m.rowList = m.top.FindNode("rowList")
    m.top.observeField("visible", "onVisibleChange")

    m.rowList       =   m.top.findNode("rowList")
    m.summary       =   m.top.findNode("summary")
    m.background    =   m.top.findNode("Background")

    m.savedContent = createObject("roSGNode","ContentNode")
    m.savedContentFocus = []

    resetContent()
    resetStack()

    m.top.observeField("visible", "onVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChildChange")

end sub

'
'   Clear existing content
'
function resetContent()
    m.summary.content = createObject("roSGNode","ContentNode")
    m.background.url = ""
    m.content = createObject("roSGNode","ContentNode")
    m.rowList.content = m.content
end function

function validItem(item)  as Boolean
    rslt = true
    rslt = rslt and (item.previewPath <> Invalid)
    rslt = rslt and (item.thumbnailPath <> Invalid)
    rslt = rslt and (item.name <> Invalid)

    return rslt
end function
'
'   Add videos to current content
'
function addContent(videoInfo)
    date = CreateObject("roDateTime")

    row = createObject("RoSGNode","ContentNode")
    row.Title = videoInfo.title
    for each item in videoInfo.videos
        if validItem(item) then
            node = createObject("roSGNode","summary_node")
            node.title = item.name

            node.uuid = item.uuid
            node.url = get_setting("server", "") + item.previewPath

            '
            ' PeerTube descriptions use markdown and, at the least, we want
            ' to remove URLs that we can't click on with Roku
            '
            ' Assume markdown hyperlinks are of the form:
            '
            ' [some text](url)
            '
            if item.description <> Invalid then
                regex1 = createObject("roRegEx", "\([A-Za-z]+:\/\/[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_:%&;\?\#\/.=]+\)", "gi")
                regex2 = createObject("roRegEx", "[\[\]]", "gi")
                text = regex1.ReplaceAll(item.description,"")
                node.description = regex2.ReplaceAll(text,"")
            else
                node.description = ""
            end if

            node.HdGridPosterUrl = get_setting("server", "") + item.thumbnailPath
            node.ShortDescriptionLine1 = item.name
            node.ShortDescriptionLine2 = ""
            node.Length=item.duration

            if (item.originallyPublishedAt <> invalid)
                date.FromISO8601String(item.originallyPublishedAt)
            else
                date.FromISO8601String(item.publishedAt)
            end if
            node.ReleaseDate = date.AsDateString("short-month-no-weekday")
            row.appendChild(node)
        end if
    end for

    m.content.appendChild(row)
    m.rowList.content.appendChild(row)
end function

function saveContent()
    m.savedContent = m.rowList.content
    m.savedContentFocus = m.rowList.rowItemFocused
end function

function restoreContent()
    m.content = m.savedContent
    m.rowList.content = m.savedContent
    m.rowList.jumpToRowItem = m.savedContentFocus
end function

function resetStack()
    m.contentStack = []
end function

function pushContent()
    state = {}
    state.focus = m.rowList.rowItemFocused
    state.content = m.rowList.content
    m.contentStack.Push(state)
end function

function popContent() as Boolean
    result = false
    state = m.contentStack.Pop()
    if (state <> invalid)
        m.content = state.content
        m.rowList.content = state.content
        m.rowList.jumpToRowItem = state.focus
        result = true
    end if
    return result
end function

' handler of focused item in RowList
Sub OnItemFocused()
    itemFocused = m.top.itemFocused

    '   When an item gains the key focus, set to a 2-element array,
    '   where element 0 contains the index of the focused row,
    '   and element 1 contains the index of the focused item in that row.
    If itemFocused.Count() = 2 then
        focusedContent = m.content.getChild(itemFocused[0]).getChild(itemFocused[1])
        if focusedContent <> invalid then
            m.top.focusedContent    = focusedContent
            m.summary.content       = focusedContent
            m.background.url        = focusedContent.HdGridPosterUrl
        end if
    end if
End Sub

sub onVisibleChange()
    if m.top.visible = true then
        m.rowList.setFocus(true)
    end if
end sub

' set proper focus to rowList in case if return from Details Screen
Sub OnFocusedChildChange()
    if m.top.isInFocusChain() and not m.rowList.hasFocus() then
        m.rowList.setFocus(true)
    end if
End Sub
