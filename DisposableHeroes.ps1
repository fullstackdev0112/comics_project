
import-module "$PSScriptRoot\core.ps1" -force

function get-dhdata
{
   param (
   [Parameter(Mandatory=$true)]
   [PSObject]$Record)

#Parameter 	Default value 	Parameter to append
#kimpath1 	index.php 	&kimpath1=newvalue
#act 	search 	&act=newvalue
#catId 		&catId=newvalue
#name 	walking+dead 	&name=newvalue
#cat_id 	0 	&cat_id=newvalue
#min_price 		&min_price=newvalue
#max_price 		&max_price=newvalue
#submit 	Search 	&submit=newvalue
   $title=$Record.title.ToUpper()
   $comic=$title.replace(" ","+")
   $fullfilter="&name=$comic"
   $site="Disposable Heroes"
   $url="http://www.kimonolabs.com/api/aaaaq44g?apikey=01f250503b7c40eb0ce695da7d74cbb1$fullfilter"
   write-debug "Accessing $url"
   write-Host "$(Get-Date) - Looking for $title @ `"$site`""

<# Postage
   1X  �1.00  1.00
   2X  �1.00  0.50 
   3X  �2.00  0.67
   4X  �2.00  0.50 
   5X  �2.00  0.40
   6X  $3.00  0.50
   7X  $3.00  0.43
   8X  $4.00  0.50
   9X  $4.00  0.44
   10X $4.00  0.40
   11X $5.50  0.55 
   50X $5.50  0.11
#>
   $dhresults=Invoke-RestMethod -Uri $url
   if ($dhresults.lastrunstatus -eq "failure")
   {
      write-host "$(Get-Date) - Run Failed" -ForegroundColor Red
      return $null
   }
   
   $results=$dhresults.results.collection1| where {$_.title -ne ""}
   $results=$results|where {$_.title.text -match "$title"}
   $counter=0
   $dh=@()

   Foreach($result in $results)
   {
      $record= New-Object System.Object
      $url="<a href=`"$($result.title.href)`">$($result.title.href)</a>"
      $record| Add-Member -type NoteProperty -name link -value $result.title.href
      $record| Add-Member -type NoteProperty -name url -value $url
      $record| Add-Member -type NoteProperty -name orderdate -value $null
      $record| Add-Member -type NoteProperty -name title -value $title

      $issue=get-issue -rawissue $result.title.text
      $temp=$result.price

      if ( ($temp.split("`n")).count -gt 1)
      {
         $price=get-price -price $temp.split("`n")[1]
      }
      else
      {
         $price=get-price -price $result.price
      }
       
      $record| Add-Member -type NoteProperty -name issue -value $issue.cover
      $record| Add-Member -type NoteProperty -name variant -value $issue.variant
      $record| Add-Member -type NoteProperty -name price -value $price.Amount
      $record| Add-Member -type NoteProperty -name currency -value $price.Currency
      $record| Add-Member -type NoteProperty -name rundate -value $dhresults.lastsuccess
      $record| Add-Member -type NoteProperty -name site -value $site
      
      $dh+=$record
      $counter++
   }
   
   write-host "$(Get-Date) - Found $counter"
   $dh
}
