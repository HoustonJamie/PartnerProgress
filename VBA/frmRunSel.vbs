
Option Explicit

Dim i As Integer


Private Sub CheckBox2_Click()

End Sub

Private Sub UserForm_Initialize()
' initialize form

    With lbxOPUnits
        For i = 2 To 36
            .AddItem Worksheets("rs").Range("B" & i).Value
        Next i
    End With

    lbxOPUnits.MultiSelect = 2

End Sub

Private Sub cmdRun_Click()
'run command --> generate forms

    Dim selOU 'selected operating units
    Dim rowNum

    Application.ScreenUpdating = False
    'clear Selected OUs in case of earlier error
        ActiveWorkbook.Sheets("rs").Select
        Sheets("rs").Range("J2:J36").ClearContents

    'move OUs from list to POPref sheet to loop over
     For selOU = 0 To lbxOPUnits.ListCount - 1
         If lbxOPUnits.Selected(selOU) = True Then
             rowNum = Range("sel_ous_cnt") + 1
             Sheets("rs").Cells(rowNum, 7).Offset(1, 0) = lbxOPUnits.list(selOU)
             lbxOPUnits.Selected(selOU) = False
         End If
     Next

   ' close form
      Unload Me

   ' run PPR code
      Call PPRpop

End Sub

Private Sub cmdClose_Click()
' close from and remove contents on close

    Unload Me

End Sub
