VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Feuil1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit                             '/// Toutes les variables doivent �tre d�clar�es
Option Base 0                               '/// Les Arrays comment � "0"



'/// PROC�DURE  : Se d�clenche lorsqu'un double clic survient sur la feuille et transmet en param�tre la range de la cellule cliqu�e
'/// PARAM�TRE  : Range, Boolean
'/// RETOUR     : Aucun (�v�nement)
Private Sub Worksheet_BeforeDoubleClick(ByVal pTarget As Range, pCancel As Boolean)
Dim checkerBoard As BoardModel
Dim pawn As PawnModel
Dim enemyPawn As PawnModel
Dim ysnp As YouShallNotPassModel
Dim deamonReapled As Integer
Dim turnCount As Integer

    'Si Cancel a sa valeur par d�faut ou �gal � False, alors apr�s la fin de cette proc�dure,
    'Excel va continuer en traitant le clic droit comme il le fait par d�faut.
    
    'Si Cancel est � True, alors Excel ne va pas faire son traitement habituel,
    'Excel consid�re que l��v�nement du clic droit est enti�rement pris en charge par la proc�dure.
    pCancel = True
    
    'on instancie un objet correspondant � notre plateau de jeu
    Set checkerBoard = New BoardModel
   
    'repr�sente le compteur d'erreurs effectu�es par le bot
    deamonReapled = 0

    'selon la section dans laquelle on a cliqu�
    Select Case checkerBoard.GetSection(pTarget)
    
        'si on a cliqu� sur le damier
        Case ESection.Game
        
            'selon la valeur actuelle de configuration de la partie
            Select Case checkerBoard.ConfigPlayer
            
                'si en mode 2 joueurs
                Case EConfig.TwoPlayers
                    
                    'si l'action correspond au mouvement d'un pion
                    If Player.Run(pTarget) Then

                        'change la couleur afficher sur le plateau
                        Call checkerBoard.SwitchTurn
                    
                        'v�rifie s'il y a un vainqueur
                        Call checkerBoard.SearchWinner
                    
                    End If
                    
                'si en mode 1 joueur
                Case EConfig.SinglePlayer
                
                    'si l'action correspond au mouvement d'un pion
                    If Player.Run(pTarget) Then
                        Call checkerBoard.SwitchTurn
                        Call checkerBoard.SearchWinner
                        
                        's'il n'y a pas de vainqueur
                        If Not checkerBoard.IsWinner Then

                            'instancie le v�rificateur
                            Set ysnp = New YouShallNotPassModel

                            'sauvegarde la configuration du plateau avant le tour du bot
                            Call ysnp.Snapshot

                            Call Bot.Run

                        'si les actions du bot correspondent a un mouvement acc�pt�
                        If ysnp.IsSuccess Then
                            deamonReapled = 0
                            Call checkerBoard.SwitchTurn
                            Call checkerBoard.SearchWinner
                        Else
                            deamonReapled = deamonReapled + 1
                        End If
                        End If
                    End If
                
                'si en mode IA vs IA
                Case EConfig.Automate
                    
                    Set ysnp = New YouShallNotPassModel
                    turnCount = 0
                    
                    'tant qu'il n'y a pas de vainqueur et qu'on a jou� moins de 300 tours
                    While Not checkerBoard.IsWinner And turnCount < 300 And deamonReapled < 3
                    
                        Call ysnp.Snapshot
                        
                        If checkerBoard.CurrentTurn = EColor.White Then
                            Call Bot.Run
                        ElseIf checkerBoard.CurrentTurn = EColor.Black Then
                            Call Bot.Run
                        End If
                        
                        If ysnp.IsSuccess Then
                            deamonReapled = 0
                            turnCount = turnCount + 1
                            Call checkerBoard.SwitchTurn
                            Call checkerBoard.SearchWinner
                        Else
                            deamonReapled = deamonReapled + 1
                        End If
                        
                    Wend
                    
                    If deamonReapled = 3 Then
                        MsgBox "You Failed"
                    End If
                    
            End Select
            
                
        'cas de clic sur la configuration des joueurs, on incr�mente la configuration
        Case ESection.ConfigPlayer
        
            'on incr�mente le type de partie dans l'ordre -> 1joueurs, 2joueurs, ia vs ia
            If checkerBoard.ConfigPlayer = EConfig.SinglePlayer Then
                checkerBoard.ConfigPlayer = EConfig.TwoPlayers
            ElseIf checkerBoard.ConfigPlayer = EConfig.TwoPlayers Then
                checkerBoard.ConfigPlayer = EConfig.Automate
            Else
                checkerBoard.ConfigPlayer = EConfig.SinglePlayer
            End If
        
        'cas de clic sur le bouton restart
        Case ESection.Restart
            'formate le plateau de jeux sur la feuille Excel
            Call BoardConstructeur.FormatBoard
            'initialise les pions � leur position de d�part
            Call BoardConstructeur.Initialisation
            
    End Select
End Sub