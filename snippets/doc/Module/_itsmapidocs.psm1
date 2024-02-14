function Get-HtmlSnippet() {
    param(
        $fileName,
        $substitutionObject=$null
    )
    $s=$null
    try {
        $s=gc ".\Documentation\htmlsnippets\$($fileName).html" -raw
    } catch {$s=$null}
    if ($null -eq $s) {$s=""}
    if ($null -ne $substitutionObject) {
        $substitutionObject | Get-Member -MemberType NoteProperty | ? {$_.definition -like "string*"} | %{
            $s=$s.Replace("###$($_.Name.ToLower())###",$substitutionObject.$($_.Name))
        }
    }
    $s
}
function New-docsPage() {
    param(
        $name,
        $title,
        $description,
        $headFileName="head",
        $bodyHeaderFileName="bodyheader",
        $bodyFooterFileName="bodyfooter",
        $sideBarFileName="sidebar"
    )
    $render={
        param(
            $docsPage
        )
        $sideBar=New-docsSideBar -docsPage $docsPage
        $docsPage | Add-Member -MemberType NoteProperty -Name "sidebar" -Value $sideBar
        $docsPage.html | Add-Member -MemberType NoteProperty -Name "sidebar" -Value $docsPage.sidebar.render($docsPage.sidebar,$docsPage)

        $s=""
        $s+='<!DOCTYPE html>'+"`r`n"
        $s+='<html lang="en">'+"`r`n" 
        $s+=$docsPage.html.head+"`r`n"
        $s+='<body class="docs-page">'+"`r`n"
        $s+=$docsPage.html.bodyheader+"`r`n"
        $s+='<div class="docs-wrapper">'+"`r`n"
        $s+=$docsPage.html.sidebar+"`r`n"
        $s+='<div class="docs-content">'+"`r`n"
        $s+='<div class="container">'+"`r`n"
        $docsPage.articles | ? {$null -ne $_} | %{
            $s+=$_.render($_)+"`r`n"
        }
        $s+='</div>'+"`r`n"
        $s+='</div>'+"`r`n"
        $s+='</div><!--//docs-wrapper-->'+"`r`n"
        $s+=$docsPage.html.bodyfooter+"`r`n"
        $s+='</body>'+"`r`n"
        $s+='</html>'
        $s
    }
    
    $docsPage=[PSCustomObject]@{
        name=$name
        title=$title
        description=$description
    }
    $docsPage | Add-Member -MemberType NoteProperty -Name "articles" -Value @()
    $docsPage | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsPage.html | Add-Member -MemberType NoteProperty -Name "head" -Value $(Get-HtmlSnippet -fileName $headFileName -substitutionObject $docsPage)
    $docsPage.html | Add-Member -MemberType NoteProperty -Name "bodyheader" -Value $(Get-HtmlSnippet -fileName $bodyHeaderFileName -substitutionObject $docsPage)
    $docsPage.html | Add-Member -MemberType NoteProperty -Name "bodyfooter" -Value $(Get-HtmlSnippet -fileName $bodyFooterFileName -substitutionObject $docsPage)
    $docsPage | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsPage
}
function New-docsSideBar() {
    param(
        $docsPage,
        $headerFileName="sidebarheader",
        $footerFileName="sidebarfooter"
    )
    $render={
        param(
            $docsSideBar,
            $docsPage
        )
        $s=""
        $s+=$docsSideBar.html.header+"`r`n"
        $i=0
        $docsPage.articles | ? {$null -ne $_} | %{
            $article=$_
            $article | Add-Member -MemberType NoteProperty -Name id -Value $("article-$($i)")
            $s+='<li class="nav-item section-title mt-3"><a class="nav-link scrollto" href="#' + $($article.id) + '"><span class="theme-icon-holder me-2"><i class="fas fa-arrow-down"></i></span>' + $($article.title) + '</a></li>'+"`r`n"
            $j=0
            $article.sections | ? {$null -ne $_} | %{
                $section=$_
                $section | Add-Member -MemberType NoteProperty -Name id -Value $("$($article.id)-section-$($j)")
                $s+='<li class="nav-item"><a class="nav-link scrollto" href="#' + $($section.id) + '">' + $($section.title) + '</a></li>'+"`r`n"
                $j+=1
            }
            $i+=1
        }
        $s+=$docsSideBar.html.footer+"`r`n"
        $s
    }
    $docsSideBar=[PSCustomObject]@{}
    $docsSideBar | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsSideBar.html | Add-Member -MemberType NoteProperty -Name "header" -Value $(Get-HtmlSnippet -fileName $headerFileName -substitutionObject $docsSideBar)
    $docsSideBar.html | Add-Member -MemberType NoteProperty -Name "footer" -Value $(Get-HtmlSnippet -fileName $footerFileName -substitutionObject $docsSideBar)
    $docsSideBar | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsSideBar
}
function New-docsArticle() {
    param(
        $title,
        $headerText,
        $headerFileName="articleheader"
    )

    $render={
        param(
            $docsArticle
        )
        $s=""
        $s+='<article class="docs-article" id="'+ $($docsArticle.id) +'">'+"`r`n"
        $s+=$docsArticle.html.articleheader+"`r`n"
        $docsArticle.sections | ? {$null -ne $_}  | %{
            $s+=$_.render($_)
        }
        $s+='</article>'+"`r`n"
        $s
    }
    
    $docsArticle=[PSCustomObject]@{
        title=$title
        headerText=$headerText
    }
    $docsArticle | Add-Member -MemberType NoteProperty -Name "sections" -Value @()
    $docsArticle | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsArticle.html | Add-Member -MemberType NoteProperty -Name "articleheader" -Value $(Get-HtmlSnippet -fileName $headerFileName -substitutionObject $docsArticle)
    $docsArticle | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsArticle
}
function New-docsSection() {
    param(
        $title
    )

    $render={
        param(
            $docsSection
        )
        $s=""
        $s+='<section class="docs-section" id="' + $($docsSection.id) + '">'+"`r`n"
        $s+='<h2 class="section-heading">' + $($docsSection.title) + '</h2>'+"`r`n"
        $docsSection.elements | ? {$null -ne $_} | %{
            $s+=$_.render($_)
        }
        $s+='</section>'+"`r`n"
        $s
    }

    $docsSection=[PSCustomObject]@{
        title=$title
    }
    $docsSection | Add-Member -MemberType NoteProperty -Name "elements" -Value @()
    $docsSection | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsSection | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsSection
}
function New-docsSectionHeader() {
    param(
        $title
    )

    $render={
        param(
            $docsSectionHeader
        )
        $s=""
        $s+='<h5 class="mt-5">' + $docsSectionHeader.title + '</h5>'+"`r`n"
        $s
    }

    $docsSectionHeader=[PSCustomObject]@{
        title=$title
    }
    $docsSectionHeader | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsSectionHeader | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsSectionHeader
}
function New-docsSectionText() {
    param(
        $text
    )

    $render={
        param(
            $docsSectionText
        )
        $s=""
        $s+='<p>' + $docsSectionText.text + '</p>'+"`r`n"
        $s
    }

    $docsSectionText=[PSCustomObject]@{
        text=$text
    }
    $docsSectionText | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsSectionText | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsSectionText
}
function New-docsApiEndPoint() {
    param(
        $method,
        $url
    )

    $render={
        param(
            $docsApiEndPoint
        )
        $s=""
        $s+='<div class="table-responsive my-4">'+"`r`n"
        $s+='<table class="table table-bordered">'+"`r`n"
        $s+='    <tbody>'+"`r`n"
        $s+='        <tr>'+"`r`n"
        $s+='            <th class="theme-bg-light">' + $docsApiEndPoint.method + '</th>'+"`r`n"
        $s+='            <td>' + $docsApiEndPoint.url + '</td>'+"`r`n"
        $s+='        </tr>'+"`r`n"
        $s+='    </tbody>'+"`r`n"
        $s+='</table>'+"`r`n"
        $s+='</div><!--//table-responsive-->'+"`r`n"
        $s
    }
    $docsApiEndPoint=[PSCustomObject]@{
        method=$method
        url=$url
    }
    $docsApiEndPoint | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsApiEndPoint | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsApiEndPoint
}
function New-docsUrlVariables() {
    param(
        $urlVariables
    )

    $render={
        param(
            $docsUrlVariables
        )
        $s=""    
        $s+='    <div class="table-responsive my-4">'+"`r`n"
        $s+='        <table class="table table-striped">'+"`r`n"
        $s+='            <thead>'+"`r`n"
        $s+='                <tr>'+"`r`n"
        $s+='                    <th scope="col">Variable name</th>'+"`r`n"
        $s+='                    <th scope="col">Required</th>'+"`r`n"
        $s+='                    <th scope="col">Description</th>'+"`r`n"
        $s+='                </tr>'+"`r`n"
        $s+='            </thead>'+"`r`n"
        $s+='            <tbody>'+"`r`n"
        $docsUrlVariables.urlVariables | ? {$null -ne $_} | %{
            $s+='                <tr>'+"`r`n"
            $s+='                    <td>' + $_.Name  + '</td>'+"`r`n"
            $s+='                    <td>' + $_.Required.tostring() + '</td>'+"`r`n"
            $s+='                    <td>' + $_.Description + '</td>'+"`r`n"
            $s+='                </tr>'+"`r`n"
        }
        $s+='            </tbody>'+"`r`n"
        $s+='        </table>'+"`r`n"
        $s+='    </div><!--//table-responsive-->'+"`r`n"
        $s
    }

    $docsUrlVariables=[PSCustomObject]@{
        urlVariables=$urlVariables
    }
    $docsUrlVariables | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsUrlVariables | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsUrlVariables
}
function New-docsRequestBody() {
    param(
        $requiredBodyFields,
        $optionalBodyFields
    )

    $render={
        param(
            $docsRequestBody
        )
        $s=""    
        $s+='						<div class="docs-code-block">'+"`r`n"
        $s+='							<pre class="shadow-lg rounded"><code class="json hljs">'+"`r`n"
        $s+='  {'+"`r`n"
        $fields=$docsRequestBody.requiredBodyFields+$docsRequestBody.optionalBodyFields | ? {$null -ne $_}
        $i=1
        $fields | %{
            $s+='    <span class="hljs-attr">"' + $_.fieldname + '"</span>: <span class="hljs-string">' + $_.testdatavalue + '</span>'+ $(if ($i -lt $fields.length) {","}) +"`r`n"
            $i+=1
        }
        $s+='  }'+"`r`n"
        $s+=''+"`r`n"
        $s+='</code></pre>'+"`r`n"
        $s+='						</div><!--//docs-code-block-->'+"`r`n"
        $s
    }

    $docsRequestBody=[PSCustomObject]@{
        requiredBodyFields=$requiredBodyFields
        optionalBodyFields=$optionalBodyFields
    }
    $docsRequestBody | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsRequestBody | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsRequestBody
}
function New-docsResponseBody() {
    param(
        $returnFields
    )

    $render={
        param(
            $docsResponseBody
        )
        $s=""    
        $s+='						<div class="docs-code-block">'+"`r`n"
        $s+='							<pre class="shadow-lg rounded"><code class="json hljs">'+"`r`n"
        $s+='  {'+"`r`n"
        $fields=$docsResponseBody.returnFields | ? {$null -ne $_}
        $i=1
        $fields | %{
            if ($_.testdatavalue -eq "-text-") {
                $s+='    <span class="hljs-attr">' + $_.fieldName + '</span>'+ $(if ($i -lt $fields.length) {","}) +"`r`n"
            } else {
                $s+='    <span class="hljs-attr">"' + $_.fieldname + '"</span>: <span class="hljs-string">' + $_.testdatavalue + '</span>'+ $(if ($i -lt $fields.length) {","}) +"`r`n"
            }
            $i+=1
        }
        $s+='  }'+"`r`n"
        $s+=''+"`r`n"
        $s+='</code></pre>'+"`r`n"
        $s+='						</div><!--//docs-code-block-->'+"`r`n"
        $s
    }

    $docsResponseBody=[PSCustomObject]@{
        returnFields=$returnFields
    }
    $docsResponseBody | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsResponseBody | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsResponseBody
}
function New-docsRequestBodyVariables() {
    param(
        $requiredBodyFields,
        $optionalBodyFields
    )

    $render={
        param(
            $docsRequestBodyVariables
        )
        $s=""    
        $s+='    <div class="table-responsive my-4">'+"`r`n"
        $s+='        <table class="table table-striped">'+"`r`n"
        $s+='            <thead>'+"`r`n"
        $s+='                <tr>'+"`r`n"
        $s+='                    <th scope="col">Variable name</th>'+"`r`n"
        $s+='                    <th scope="col">Required</th>'+"`r`n"
        $s+='                    <th scope="col">Description</th>'+"`r`n"
        $s+='                </tr>'+"`r`n"
        $s+='            </thead>'+"`r`n"
        $s+='            <tbody>'+"`r`n"
        $docsRequestBodyVariables.requiredBodyFields | ? {$null -ne $_} | %{
            $s+='                <tr>'+"`r`n"
            $s+='                    <td>' + $_.fieldname  + '</td>'+"`r`n"
            $s+='                    <td>' + "True" + '</td>'+"`r`n"
            $s+='                    <td>' + $_.Description + '</td>'+"`r`n"
            $s+='                </tr>'+"`r`n"
        }
        $docsRequestBodyVariables.optionalBodyFields | ? {$null -ne $_} | %{
            $s+='                <tr>'+"`r`n"
            $s+='                    <td>' + $_.fieldname  + '</td>'+"`r`n"
            $s+='                    <td>' + "False" + '</td>'+"`r`n"
            $s+='                    <td>' + $_.Description + '</td>'+"`r`n"
            $s+='                </tr>'+"`r`n"
        }
        $s+='            </tbody>'+"`r`n"
        $s+='        </table>'+"`r`n"
        $s+='    </div><!--//table-responsive-->'+"`r`n"
        $s
    }

    $docsRequestBodyVariables=[PSCustomObject]@{
        requiredBodyFields=$requiredBodyFields
        optionalBodyFields=$optionalBodyFields
    }
    $docsRequestBodyVariables | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsRequestBodyVariables | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsRequestBodyVariables
}
function New-docsResponseBodyVariables() {
    param(
        $returnFields
    )

    $render={
        param(
            $docsResponseBodyVariables
        )
        $s=""    
        $s+='    <div class="table-responsive my-4">'+"`r`n"
        $s+='        <table class="table table-striped">'+"`r`n"
        $s+='            <thead>'+"`r`n"
        $s+='                <tr>'+"`r`n"
        $s+='                    <th scope="col">Variable name</th>'+"`r`n"
        $s+='                    <th scope="col">Description</th>'+"`r`n"
        $s+='                </tr>'+"`r`n"
        $s+='            </thead>'+"`r`n"
        $s+='            <tbody>'+"`r`n"
        $docsResponseBodyVariables.returnFields | ? {$null -ne $_} | %{
            $s+='                <tr>'+"`r`n"
            $s+='                    <td>' + $_.fieldname  + '</td>'+"`r`n"
            $s+='                    <td>' + $_.Description + '</td>'+"`r`n"
            $s+='                </tr>'+"`r`n"
        }
        $s+='            </tbody>'+"`r`n"
        $s+='        </table>'+"`r`n"
        $s+='    </div><!--//table-responsive-->'+"`r`n"
        $s
    }

    $docsResponseBodyVariables=[PSCustomObject]@{
        returnFields=$returnFields
    }
    $docsResponseBodyVariables | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsResponseBodyVariables | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsResponseBodyVariables
}
function New-docsNoteCallout() {
    param(
        $text,
        $title="Note"
    )

    $render={
        param(
            $docsNoteCallout
        )
        $s=""
        $s+='                        <div class="callout-block callout-block-info">'+"`r`n"
        $s+='                            '+"`r`n"
        $s+='                            <div class="content">'+"`r`n"
        $s+='                                <h4 class="callout-title">'+"`r`n"
        $s+='	                                <span class="callout-icon-holder me-1">'+"`r`n"
        $s+='		                                <i class="fas fa-info-circle"></i>'+"`r`n"
        $s+='		                            </span><!--//icon-holder-->'+"`r`n"
        $s+=$($docsNoteCallout.title) +"`r`n"
        $s+='	                            </h4>'+"`r`n"
        $s+='                                <p>' + $($docsNoteCallout.text) + '</p>'+"`r`n"
        $s+='                            </div><!--//content-->'+"`r`n"
        $s+='                        </div><!--//callout-block-->'+"`r`n"       
        $s
    }

    $docsNoteCallout=[PSCustomObject]@{
        text=$text
        title=$title
    }
    $docsNoteCallout | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsNoteCallout | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsNoteCallout
}
function New-docsTable() {
    param(
        $records
    )

    $render={
        param(
            $docsTable
        )
        $s=""    
        $s+='    <div class="table-responsive my-4">'+"`r`n"
        $s+='        <table class="table table-striped">'+"`r`n"
        $s+='            <thead>'+"`r`n"
        $s+='                <tr>'+"`r`n"
        if ($docsTable.records.length -gt 0) {
            $docsTable.records[0] | Get-Member -MemberType NoteProperty | select -ExpandProperty name | sort | %{
                $s+='                    <th scope="col">' + $($_.Substring(1)) + '</th>'+"`r`n"
            }
        }
        $s+='                </tr>'+"`r`n"
        $s+='            </thead>'+"`r`n"
        $s+='            <tbody>'+"`r`n"
        if ($docsTable.records.length -gt 0) {
            $docsTable.records | ? {$null -ne $_} | %{
                $s+='                <tr>'+"`r`n"
                $record=$_
                $record | Get-Member -MemberType NoteProperty | select -ExpandProperty name | sort | %{
                    $s+='                    <td>' + $($record.$($_))  + '</td>'+"`r`n"
                }
                $s+='                </tr>'+"`r`n"
            }
        }
        $s+='            </tbody>'+"`r`n"
        $s+='        </table>'+"`r`n"
        $s+='    </div><!--//table-responsive-->'+"`r`n"
        $s
    }

    $docsTable=[PSCustomObject]@{
        records=$records
    }
    $docsTable | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsTable | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsTable
}
function New-docsButton() {
    param(
        $caption,
        $link,
        $class="btn btn-primary"
    )
    $render={
        param(
            $docsButton
        )
        $s=""
        $s+='<p><a href="' + $($docsButton.link) + '" class="' + $($docsButton.class) + '">' + $($docsButton.caption) + '</a></p>'
        $s
    }

    $docsButton=[PSCustomObject]@{
        caption=$caption
        link=$link
        class=$class
    }
    $docsButton | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsButton | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsButton
}
function New-docsIndexPage() {
    param(
        $title,
        $headFileName="indexhead",
        $indexPageHeaderFileName="indexpageheader",
        $indexBodyHeaderFileName="indexbodyheader",
        $indexBodyFooterFileName="indexbodyfooter"
    )
    $render={
        param(
            $docsIndexPage
        )
        $s=""
        $s+='<!DOCTYPE html>'+"`r`n"
        $s+='<html lang="en"> '+"`r`n"
        $s+=$docsIndexPage.html.head+"`r`n"
        $s+='<body>'+"`r`n"
        $s+=$docsIndexPage.html.indexbodyheader+"`r`n"
        $s+=$docsIndexPage.html.indexpageheader+"`r`n"
        $s+='   <div class="page-content">'+"`r`n"
        $s+='	    <div class="container">'+"`r`n"
        $s+='		    <div class="docs-overview py-5">'+"`r`n"
        $s+='			    <div class="row justify-content-center">'+"`r`n"
        $docsIndexPage.cards | ? {$null -ne $_} | %{
            $s+=$_.render($_)+"`r`n"
        }
        $s+=''+"`r`n"
        $s+=''+"`r`n"
        $s+=''+"`r`n"
        $s+='			    </div><!--//row-->'+"`r`n"
        $s+='		    </div><!--//container-->'+"`r`n"
        $s+='		</div><!--//container-->'+"`r`n"
        $s+='    </div><!--//page-content-->'+"`r`n"
        $s+=$docsIndexPage.html.indexbodyfooter+"`r`n"
        $s+='</body>'+"`r`n"
        $s+='</html> '+"`r`n"
        $s
    }
    $docsIndexPage=[PSCustomObject]@{
        title=$title
    }
    $docsIndexPage | Add-Member -MemberType NoteProperty -Name "cards" -Value @()
    $docsIndexPage | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsIndexPage.html | Add-Member -MemberType NoteProperty -Name "head" -Value $(Get-HtmlSnippet -fileName $headFileName -substitutionObject $docsIndexPage)
    $docsIndexPage.html | Add-Member -MemberType NoteProperty -Name "indexpageheader" -Value $(Get-HtmlSnippet -fileName $indexPageHeaderFileName -substitutionObject $docsIndexPage)
    $docsIndexPage.html | Add-Member -MemberType NoteProperty -Name "indexbodyheader" -Value $(Get-HtmlSnippet -fileName $indexBodyHeaderFileName -substitutionObject $docsIndexPage)
    $docsIndexPage.html | Add-Member -MemberType NoteProperty -Name "indexbodyfooter" -Value $(Get-HtmlSnippet -fileName $indexBodyFooterFileName -substitutionObject $docsIndexPage)
    $docsIndexPage | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsIndexPage
}
function New-docsIndexCard() {
    param(
        $icon,
        $title,
        $text,
        $link,
        $indexCardFileName="indexcard"
    )
    $render={
        param(
            $docsIndexCard
        )
        $s=""
        $s+=$docsIndexCard.html.indexcard+"`r`n"
        $s
    }
    $docsIndexCard=[PSCustomObject]@{
        icon=$icon
        title=$title
        text=$text
        link=$link
    }
    $docsIndexCard | Add-Member -MemberType NoteProperty -Name "html" -Value $([PSCustomObject]@{})
    $docsIndexCard.html | Add-Member -MemberType NoteProperty -Name "indexcard" -Value $(Get-HtmlSnippet -fileName $indexCardFileName -substitutionObject $docsIndexCard)
    $docsIndexCard | Add-Member -MemberType ScriptMethod -Name "render" -Value $render
    $docsIndexCard
}
function Get-DocuFunctions() {
    param(

    )
    ipmo .\ApiTesting\Module\itsmapiutils.psm1 -WarningAction SilentlyContinue -Force
    $solutionBasePath="Azure Functions"
    $r=Get-iapSchema
    $apiSchema=($r.Value).apiSchema

    $publicSecret="H4sIAAAAAAAACg3GN4KjMAAAwAdRmChDsQVZBNtLDh1BsFiAMUGE199NNRyKn9Nzdr/OedEUeBs+8zjRu4Go9ZPr82FIUcHjplJ985j8/wennTdaiLgi3YXMtc2BezL0OU+Yw4ba9l35V0l+W+hu3X+UUtUzPhw9d81L3lIPp2sX7ZA3YZFbqQxp6C6Daf826N3f/c1qAwTrxydg55NtvlOdAhXEeuzEl0WgxrNj5gqJYdjsgBpMw60OFGc/IU9ryETuBkmzMiT+Isbo7uGgieDVefO6YRUaS6UoNBRrHHvKTK7ycMuZPekntIitfNNoDKMgMrnXg7S/ehjGlTiou3zqmaMnKSXUzbjFYsr6aj/f/R2Pp5rzGa2ly6GQiDlg74O14SYC9doVV7xEZpVwXncp7RFZZiOPVpl5A7gN9rxK2JQIJQOXygxgGkoi5UqyVoU+Zn/pbjGoMuTVs/EC+nzh5kW/JhR15hprbysENyEm2p5Q/DhoW49GiCU8F1rwTP3Jvr2Cqth/fv4BVE4oz9gBAAA="
    $r=Get-iapAccessToken -resourceURI $global:dvEnvironmentUrl
    $dvToken=$r.Value
    $r=Get-iapdvdata -envUri $global:dvEnvironmentUrl -accessToken $dvToken -tableName "itsmapi_customers" -filter "statecode eq 0"
    $allCustomers=$r.Value
    @("internal","public","manage") | %{
        $section=$_
        $apiSchema | ? {$_.deftype -eq 0 -and $_.$($section) -eq 1} | %{
            if ($($_ | get-member -MemberType NoteProperty | select -ExpandProperty name) -notcontains "testdatavalue") {
                $t=Get-TestData -testdata $($_.testdata) -section $section -customerSecret $publicSecret -allCustomers $allCustomers -masq $true
                $_ | Add-Member -MemberType NoteProperty -Name "testdatavalue" -Value $t
            }
        }    
    }

    $texts=$(gc .\Documentation\texts.json) | convertfrom-json

    $docuFunctions=@()
    $functionNames=gci -Path $solutionBasePath -Directory | ? {$_.name -like '*_internal' -or $_.name -like '*_public' -or $_.name -like '*_manage'} | select -ExpandProperty name
    $functionNames | %{
        $functionName=$_
        $splt=$functionName.split("_")
        $entity=$splt[-3]
        $tableName="itsmapi_$($entity)s"
        $idFieldName="$($entity)id"
        if ($entity -eq 'allowedip') {$tableName="itsmapi_customerips"}
        if ($entity -eq 'allowedurl') {$tableName="itsmapi_customerurls"}
        $method=$splt[-2]
        $section=$splt[-1]
        $requiredBodyFields=@($apiSchema | ?{$_.defType -eq 0 -and $_.tableName -eq $tableName -and $_.req -eq 1 -and $_.$($section) -eq 1})
        $optionalBodyFields=@($apiSchema | ?{$_.defType -eq 0 -and $_.tableName -eq $tableName -and $_.req -eq 0 -and $_.$($section) -eq 1}) 
        $returnFields=@($apiSchema | ?{$_.defType -eq 0 -and $_.tableName -eq $tableName -and $_.$($section) -eq 1 -and $_.expression -ne 'none'})

        $entityTitle=$texts.entity.$($entity).title
        $entityDescription=$texts.entity.$($entity).description
        $sectionTitle=$texts.section.$($section).title
        $sectionDescription=$texts.section.$($section).description       

        $urlVariables=@()
        $functionDef=$(gc -Path "$($solutionBasePath)\$($functionName)\function.json") | ConvertFrom-Json
        $routeSplt=$($functionDef.bindings.route | out-string).split("/")
        for ($i=0;$i -lt $routeSplt.length;$i++) {
            if ($routeSplt[$i].Trim() -like "{*}") {
                $variableRequired=$(!([char[]]$routeSplt[$i].Trim() -contains "?"))
                $routeSplt[$i]="{$($routeSplt[$i-1])id}"
                $variableName="$($routeSplt[$i-1])id"
                $variableTableName="itsmapi_$($($routeSplt[$i-1]))s"
                if ($($routeSplt[$i-1]) -eq "allowedip") {$variableTableName="itsmapi_customerips"}
                if ($($routeSplt[$i-1]) -eq "allowedurl") {$variableTableName="itsmapi_customerurls"}                
                $variableDescription=$($apischema | ? {$_.fieldname -like "$($routeSplt[$i-1])id" -and $_.tablename -like $variableTableName} | select -expandproperty description)
                $urlVariables+=[PSCustomObject]@{
                    Name = $variableName
                    Required=$variableRequired
                    Description=$variableDescription
                }
            }
        }
        $functionRoute=$($routeSplt -join '/').replace("`r`n","")
        $url="/api/$($functionRoute)"

        $functionDescription=$((gc -Path "$($solutionBasePath)\$($functionName)\run.ps1") | select -First 1).replace("#","").Trim()
        if ($functionDescription -notlike "*.") {$functionDescription+="."}

        #special cases
        if ($entity -eq "value" -and $url -like "*incident*attachment*") {
            $entity="incidentattachment"
            $returnFields=@(
                [PSCustomObject]@{
                    fieldName="[array of byte]"
                    testdatavalue="-text-"
                    Description="Byte array of the file content"
                }
            )
        }
        if ($entity -eq "secret" -and $url -like "*customer*secret") {
            $entity="customersecret"
            $returnFields=@(
                [PSCustomObject]@{
                    fieldName="customersecret"
                    testdatavalue="dHGHTkjkhJHjJHjIhhjHjHJgRtdFdGGKJHLKH..."
                    Description="The secret/token for the customer record."
                }
            )
        }
        
        $docuFunctions+=[PSCustomobject]@{
            tableName=$tableName
            idFieldName=$idFieldName
            entity=$entity
            method=$method
            section=$section
            url=$url
            requiredBodyFields=$requiredBodyFields
            optionalBodyFields=$optionalBodyFields
            returnFields=$returnFields
            functionDescription=$functionDescription
            urlVariables=$urlVariables
            functionDef=$functionDef
            entityTitle=$entityTitle
            entityDescription=$entityDescription
            sectionTitle=$sectionTitle
            sectionDescription=$sectionDescription
        }
    }
    $docuFunctions
}
function Get-DocuSites() {
    param(
        $docuFunctions
    )
    @("manage","internal","public") | % {
        $section=$_
        $sectionFunctions=$docuFunctions | ? {$_.section -eq $section} | group entity
    
        $docsPage=New-docsPage -name DocsPage -title $($sectionFunctions[0].Group[0].sectionTitle) -description $($sectionFunctions[0].Group[0].sectionDescription)

        $docsArticle=New-docsArticle -title $($sectionFunctions[0].Group[0].sectionTitle) -headerText  $($sectionFunctions[0].Group[0].sectionDescription)
        $docsPage.articles+=$docsArticle

        $sectionFunctions | ? {$null -ne $_} | % {
            $_.Group | Add-Member -MemberType NoteProperty -Name "urllength" -Value $($_.group | ? {$_.method -eq "GET"} | Select -First 1 | select  @{Name="urllength";Expression={$_.url.length}} | select -ExpandProperty urllength) -Force
        }
        $sectionFunctions | Sort -Property @{Expression={$_.group.urllength}} | % {
            $entityFunctions=$_.group
    
            $docsArticle=New-docsArticle -title $($entityFunctions[0].entityTitle) -headerText $($entityFunctions[0].entityDescription)
    
            @("GET","POST","PATCH","DELETE") | % {
                $method=$_
                $entityMethod=$entityFunctions | ? {$_.method -eq $method}
                if ($null -ne $entityMethod) {
    
                    $docsSection=New-docsSection -title $entityMethod.method
                    $docsSection.elements+=New-docsSectionText -text $entityMethod.functionDescription
                    $docsSection.elements+=New-docsApiEndPoint -method $entityMethod.method -url $entityMethod.url                
                    if ($entityMethod.urlVariables.length -gt 0) {
                        $docsSection.elements+=New-docsSectionHeader -title "URL variables"
                        $docsSection.elements+=New-docsUrlVariables -urlVariables $entityMethod.urlVariables
                    }
                    if ($entityMethod.method -in @("POST","PATCH")) {
                        $docsSection.elements+=New-docsSectionHeader -title "Request body"
                        $docsSection.elements+=New-docsRequestBody -requiredBodyFields $entityMethod.requiredBodyFields -optionalBodyFields $entityMethod.optionalBodyFields
                        $docsSection.elements+=New-docsSectionHeader -title "Request body fields"
                        $docsSection.elements+=New-docsRequestBodyVariables -requiredBodyFields $entityMethod.requiredBodyFields -optionalBodyFields $entityMethod.optionalBodyFields
                    }
                    if ($entityMethod.method -in @("GET","POST","PATCH")) {
                        $docsSection.elements+=New-docsSectionHeader -title "Response body"
                        $docsSection.elements+=New-docsResponseBody -returnFields $entityMethod.returnFields
                        $docsSection.elements+=New-docsSectionHeader -title "Response body fields"
                        $docsSection.elements+=New-docsResponseBodyVariables -returnFields $entityMethod.returnFields      
                    }
                    $docsArticle.sections+=$docsSection
                }                
            }
            $docsPage.articles+=$docsArticle
        }
        $docsPage.render($docsPage) | out-file ".\Documentation\$($section).html"
    }       
}
function Get-IndexPage() {
    param(

    )
   $docsIndexPage=New-docsIndexPage -title "Wagner AG - Spidertalk API"
   $docsIndexPage.cards+=New-docsIndexCard -icon "fa-square-check" -title "General" -text "General" -link "general.html"
   $docsIndexPage.cards+=New-docsIndexCard -icon "fa-solid fa-check-circle" -title "Public" -text "Public" -link "public.html"
   $docsIndexPage.cards+=New-docsIndexCard -icon "fa-solid  fa-cloud-upload" -title "Internal" -text "Internal" -link "internal.html"
   $docsIndexPage.cards+=New-docsIndexCard -icon "fa-cogs fa-fw" -title "Manage" -text "Manage" -link "manage.html"
   $docsIndexPage.render($docsIndexPage) | out-file ".\Documentation\index.html"
}
function Get-GeneralSite() {
    param(

    )
    $docsPage=New-docsPage -name DocsPage -title "General documentation" -description "This site contains general information about the usage of the API."

    $texts=$(gc .\Documentation\texts.json) | convertfrom-json
    $texts.general.articles | ? {$null -ne $_} | % {
        $article=$_
        $docsArticle=New-docsArticle -title $article.title -headerText $article.text
        $article.sections | ? {$null -ne $_} | %{
            $section=$_
            $docsSection=New-docsSection -title $section.title
            $section.elements | ? {$null -ne $_} | % {
                $element=$_
                switch ($element.type) {
                    "text" {
                        if ($null -ne $element.title) {
                            $docsSection.elements+=New-docsSectionHeader -title $element.title
                        }
                        if ($null -ne $element.text) {
                            $docsSection.elements+=New-docsSectionText -text $element.text                        
                        }
                        break
                    }
                    "table" {
                        if ($null -ne $element.title) {
                            $docsSection.elements+=New-docsSectionHeader -title $element.title
                        }
                        if ($null -ne $element.records) {
                            $docsSection.elements+=New-docsTable -records $element.records
                        }
                        break
                    }
                    "button" {
                        if ($null -ne $elememt.class) {
                            $docsSection.elements+=New-docsButton -caption $element.caption -link $element.link -class $element.class
                        } else {
                            $docsSection.elements+=New-docsButton -caption $element.caption -link $element.link
                        }
                        break
                    }
                }    
            }
            $docsArticle.sections+=$docsSection
        }
        $docsPage.articles+=$docsArticle
    }
    $docsPage.render($docsPage) | out-file ".\Documentation\general.html"
}
