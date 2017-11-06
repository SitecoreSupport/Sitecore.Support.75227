<%@ Page Language="C#" Debug="true" Async="true" %>

<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Sitecore.Support.75227</title>
    <script runat="server">

      protected void btn_Update_Click(object sender, EventArgs e)
      {
         
          result.Text +="Fix WFFM Lists After Migration - started <br />";

          var masterDB = Sitecore.Data.Database.GetDatabase("master");
          Item formsRootItem = masterDB.GetItem(tbItem.Text);

         
          if (formsRootItem == null)
          {
              result.Text += "The root item specified is null";
              return;

          }

          var listFields = formsRootItem.Axes.GetDescendants()
              .Where(i => i.TemplateID == new Sitecore.Data.ID("{C9E1BF85-800A-4247-A3A3-C3F5DFBFD6AA}"))
              .Where(i => i.Fields["Field Link"].Value == "{C6D97C39-23B5-4B7E-AFC7-9F41795533C6}"
                          || i.Fields["Field Link"].Value == "{CDD533E2-918A-4BE3-A12F-83A8580363F7}"
                          || i.Fields["Field Link"].Value == "{0FAE4DE2-5C37-45A6-B474-9E3AB95FF452}"
                          || i.Fields["Field Link"].Value == "{E994EAE0-EDB0-4D89-B545-FEBEF07DD7CD}")
              .Where(i => i.Fields["Parameters"].Value.ToLower().Contains("<items")
              ).ToList();
          result.Text += string.Format("{0} List Fields with the old format data were found <br />", listFields.Count);
          foreach (var listFieldItem in listFields)
          {
              result.Text += string.Format("*** The \"{0}\" field item is processed *** <br />", listFieldItem.Paths.FullPath);
              Regex regex = new Regex("<Items*?>(.*?)</Items>");
              MatchCollection matches = regex.Matches(listFieldItem.Fields["Parameters"].Value);
              bool addedToLangVersion = false;
              result.Text += string.Format("{0} &lt;Items matches <br />", matches.Count);
              if (matches.Count == 1)
              {
                  string listItemsStr = matches[0].Value;
                  foreach (var langVersion in listFieldItem.Languages)
                  {
                      result.Text += string.Format("The \"{0}\" language is being processed <br />", langVersion.Name);
                      Item langItem = masterDB.GetItem(listFieldItem.ID, langVersion);
                      if (!langItem.Fields["Localized Parameters"].Value.ToLower().Contains("<items"))
                      {
                          langItem.Editing.BeginEdit();
                          langItem.Fields["Localized Parameters"].Value =
                              listItemsStr + langItem.Fields["Localized Parameters"].Value;
                          langItem.Editing.EndEdit();
                          result.Text +="The &lt;Items collection was inserted to the Localized Parameters<br />";
                          addedToLangVersion = true;
                      }
                  }
                  if (addedToLangVersion)
                  {
                      listFieldItem.Editing.BeginEdit();
                      listFieldItem.Fields["Parameters"].Value =
                          listFieldItem.Fields["Parameters"].Value.Replace(listItemsStr, string.Empty);
                      listFieldItem.Editing.EndEdit();
                      result.Text += "The <Items collection was removed from the Parameters<br />";
                  }
              }
              result.Text += string.Format("*** The \"{0}\" field item finished ***<br />", listFieldItem.Paths.FullPath);

          }
      }


    </script>
</head>
<body>
<form id="form1" runat="server">
    <div>
        Forms root item:<asp:TextBox ID="tbItem" Text="/sitecore/system/Modules/Web Forms for Marketers/" Width="400" runat="server" /><br />
        <asp:Button ID="btn_Update" runat="server" OnClick="btn_Update_Click" Text="Update" /><br />
        Result: <br /><asp:Label runat="server" ID="result"></asp:Label>
    </div>
</form>
</body>
</html>
