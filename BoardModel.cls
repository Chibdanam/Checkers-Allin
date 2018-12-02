VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "BoardModel"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Option Base 0

'/// CONSTRUCTEUR: m�thode appel� lors de l'instanciation de l'objet
'/// PARAM�TRE   : Aucun
'/// RETOUR      : Aucun
Private Sub class_Initialize()
End Sub



'/// DESTRUCTEUR: m�thode appel� lors de la destruction de l'objet
'/// PARAM�TRE  : Aucun
'/// RETOUR     : Aucun
Private Sub class_Terminate()
End Sub



'/// PROPRI�T�  : Retourne le nom de la section dans laquelle se trouve la Range pass�e en param�tre
'/// PARAM�TRE  : Range
'/// RETOUR     : ESection
Public Property Get GetSection(ByVal pCell As Range) As ESection

    'par d�faut, on d�finit la valeur de retour � Hors limite
    GetSection = ESection.OutOfLimit
    
    'si la cellule est comprise danse une des sections connues du plateau, alors on renvoi la valeur de la section
    If Not (Application.Intersect(pCell, Range("Game")) Is Nothing) Then
        GetSection = ESection.Game
    ElseIf Not (Application.Intersect(pCell, Range("ConfigPlayer")) Is Nothing) Then
        GetSection = ESection.ConfigPlayer
    ElseIf Not (Application.Intersect(pCell, Range("Restart")) Is Nothing) Then
        GetSection = ESection.Restart
    End If

End Property



'/// PROPRI�T�  : Retourne la valeur de l'�num�ration EColor associ�e de la valeur �crite sur le damier
'/// PARAM�TRE  : Aucun
'/// RETOUR     : EColor
Public Property Get CurrentTurn() As EColor

    If Range("TurnValue") = EnumString(EColor.White) Then
        CurrentTurn = EColor.White
    ElseIf Range("TurnValue") = EnumString(EColor.Black) Then
        CurrentTurn = EColor.Black
    Else
        'Si aucune valeur attendue n'est trouv�e, on la param�tre � "White" par d�faut
        CurrentTurn = EColor.White
        Range("TurnValue") = EnumString(EColor.White)
    End If
    
End Property



'/// PROC�DURE  : Change la couleur affich�e sur le plateau de jeu
'/// PARAM�TRE  : Aucun
'/// RETOUR     : Aucun
Public Sub SwitchTurn()

    If Range("TurnValue") <> "You Win" Then
        If Me.CurrentTurn = EColor.Black Then
            Me.CurrentTurn = EColor.White
        ElseIf Me.CurrentTurn = EColor.White Then
            Me.CurrentTurn = EColor.Black
        End If
    End If
    
End Sub



'/// PROPRI�T�  : Retourne la couleur du joueur du tour en cours
'/// PARAM�TRE  : Aucun
'/// RETOUR     : Aucun
Property Let CurrentTurn(ByVal pColor As EColor)
    Range("TurnValue") = EnumString(pColor)
End Property



'/// PROPRI�T�  : Retourne la configuration actuelle du plateau jeu (1 joueur, 2 joueurs, ia vs ia)
'/// PARAM�TRE  : Aucun
'/// RETOUR     : EConfig
Public Property Get ConfigPlayer() As EConfig
    
    If Range("ConfigPlayerValue") = EnumString(EConfig.SinglePlayer) Then
        ConfigPlayer = EConfig.SinglePlayer
    ElseIf Range("ConfigPlayerValue").Value = EnumString(EConfig.TwoPlayers) Then
        ConfigPlayer = EConfig.TwoPlayers
    ElseIf Range("ConfigPlayerValue").Value = EnumString(EConfig.Automate) Then
        ConfigPlayer = EConfig.Automate
    Else
        'Si aucune valeur attendue n'est trouv�e, on la param�tre a "1 Player" par d�faut
        ConfigPlayer = EConfig.SinglePlayer
        Range("ConfigPlayerValue") = EnumString(EConfig.SinglePlayer)
    End If
    
End Property



'/// PROPRI�T�  : Modifie la configuration du plateau de jeu
'/// PARAM�TRE  : EConfig
'/// RETOUR     : Aucun
Public Property Let ConfigPlayer(ByVal pConfig As EConfig)
        Range("ConfigPlayer") =  EnumString(pConfig)
End Property



'/// PROPRI�T�  : �cris sur le plateau de jeu dans la zone "m�moire" la position du pion pass� en param�tre
'/// PARAM�TRE  : PawnModel
'/// RETOUR     : Aucun
Public Property Let Memory(ByVal pPawn As PawnModel)
Dim Column As String
Dim Row As String
Dim offset As Integer

    'permet d'�crire sur le plateau les coordonn�es dans le r�f�rentiel du plateau et non le r�f�rentiel d�Excel
    'le damier commen�ant en "B2", on a un offset de 1 sur la colonne et de 1 sur la ligne par rapport � "A1"
    offset = 1
    
    'afin de r�cup�rer la lettre correspondant � la colonne, on convertie la valeur de la colonne en caract�re ASCII
    Column = Chr(64 + (pPawn.CurrentRange.Column - offset))
    'on convertie notre valeur num�rique en chaine de caract�re : Integer to String
    Row = CStr(pPawn.CurrentRange.Row - offset)
    
    Range("MemoryValue").Value = Column + Row
        
End Property



'/// PROPRI�T�  : Retourne le pion �cris en m�moire sur le plateau de jeu
'/// PARAM�TRE  : Aucun
'/// RETOUR     : PawnModel
Public Property Get Memory() As PawnModel
Dim offsetPawnPosition As String
Dim offsetPawnRange As Range
Dim pawnRange As Range
Dim offset As Integer
    
    Set Memory = New PawnModel
    
    offset = 1
    
    'si la range "m�moire" n'est pas vie
    If Not IsEmpty(Range("MemoryValue")) Then
        
        'on r�cup�re la valeur �crite sur le plateau
        offsetPawnPosition = Range("MemoryValue").Value
        
        'r�cup�re la cellule dans le r�f�rentiel du damier
        Set offsetPawnRange = Range(offsetPawnPosition)
        
        'r�cup�re la v�ritable cellule dans le r�f�rentiel d�Excel
        Set pawnRange = Cells(offsetPawnRange.Row + offset, offsetPawnRange.Column + offset)
        
        'on construit le pion avec la cellule pr�c�demment r�cup�r�
        Call Memory.Build(pawnRange)
        
    End If
    
End Property



'/// PROC�DURE  : Ecris sur le plateau de jeu "You Win" s�il ne reste qu'un seul joueur
'/// PARAM�TRE  : Aucun
'/// RETOUR     : Aucun
Public Sub SearchWinner()
Dim whiteFound As Boolean
Dim blackFound As Boolean
Dim pawn As PawnModel
Dim cell As Range
    
    whiteFound = False
    blackFound = False
    
    'pour chaque cellule du damier
    For Each cell In Range("Game")
        
        'on instancie et construit un pion avec la cellule actuelle
        Set pawn = New PawnModel
        Call pawn.Build(cell)
        
        'si le pion est v�ritablement un pion
        If pawn.IsPawn Then
        
            'si le pion est noir
            If pawn.Color = EColor.Black Then
                blackFound = True
                
            'si le pion est blanc
            Else
                whiteFound = True
            End If
            
            'si on a trouv� un pion blanc et un pion noir
            If whiteFound And blackFound Then
                Exit For
            End If
            
        End If
    Next cell
    
    'si une des couleurs n'est pas trouv�
    If Not whiteFound Or Not blackFound Then
        Range("TurnValue") = "You Win"
    End If
    
End Sub



'/// PROPRI�T�  : Retourne true si "You win" est �cris sur le plateau
'/// PARAM�TRE  : Aucun
'/// RETOUR     : Boolean
Property Get IsWinner() As Boolean

    IsWinner = False
    
    If Range("TurnValue") = "You Win" Then
        IsWinner = True
    End If
    
End Property



'/// PROPRI�T�  : Retourne un tableau comprenant les coefficients associ�s � la direction du d�placement
'/// PARAM�TRE  : Aucun
'/// RETOUR     : Variant (tableau de la forme (x,y))
Property Get CardinalCoef(ByVal pDirection As EWindRose) As Variant
    
    If pDirection = EWindRose.SouthEast Then
        CardinalCoef = Array(1, 1)
    ElseIf pDirection = EWindRose.NorthEast Then
        CardinalCoef = Array(-1, 1)
    ElseIf pDirection = EWindRose.SouthWest Then
        CardinalCoef = Array(1, -1)
    ElseIf pDirection = EWindRose.NorthWest Then
        CardinalCoef = Array(-1, -1)
    End If
    
End Property