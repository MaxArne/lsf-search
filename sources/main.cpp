#include <stdlib.h>
#include <iostream>
#include <string>
#include <algorithm>
#include <map>

#include "fcgio.h"

// #include <template.h>

 #include <ctemplate/template.h>

using namespace std;

const unsigned long STDIN_MAX = 1000000;

string get_request_content(const FCGX_Request & request) {
    char * content_length_str = FCGX_GetParam("CONTENT_LENGTH", request.envp);
    unsigned long content_length = STDIN_MAX;

    if (content_length_str) {
        content_length = strtol(content_length_str, &content_length_str, 10);
        if (*content_length_str) {
            cerr << "Can't Parse 'CONTENT_LENGTH='"
                 << FCGX_GetParam("CONTENT_LENGTH", request.envp)
                 << "'. Consuming stdin up to " << STDIN_MAX << endl;
        }

        if (content_length > STDIN_MAX) {
            content_length = STDIN_MAX;
        }
    } else {
        content_length = 0;
    }

    char * content_buffer = new char[content_length];
    cin.read(content_buffer, content_length);
    content_length = cin.gcount();
    do cin.ignore(1024); while (cin.gcount() == 1024);

    string content(content_buffer, content_length);
    delete [] content_buffer;
    return content;
}

std::string renderHTML(string uri, string http_request_content){

  std::string output;

  ctemplate::TemplateDictionary dict("main");
  dict.SetValue("TITLE", "LSF Sucher");

  ctemplate::TemplateDictionary* sub_dict;

  sub_dict = dict.AddIncludeDictionary("HEADER_TEMPLATE");
  sub_dict->SetFilename("templates/header.tpl");

  sub_dict = dict.AddIncludeDictionary("JAVASCRIPT_TEMPLATE");
  sub_dict->SetFilename("templates/javascript.tpl");

  sub_dict = dict.AddIncludeDictionary("NAVBAR_TEMPLATE");
  sub_dict->SetFilename("templates/navbar.tpl");

  std::transform(uri.begin(), uri.end(), uri.begin(), ::tolower);

  // Remove leading slash
  string route = uri.substr(1, uri.length()-1);

  // Remove trailing slash
  char endch = route.back();
  if ( endch == '/' ) {
     route = route.substr(0, route.length()-1);
  }

  // map <string, string> NAV_ACTIVE;
  // NAV_ACTIVE.insert(pair <string, string> (std::string("events"), std::string("NAV_EVENTS_ACTIVE")));
  // NAV_ACTIVE.insert(pair <string, string> (std::string("buildings"), std::string("NAV_BUILDINGS_ACTIVE")));


 //  std::map<char,int>::iterator it;
 //
 // it = mymap.find("ev");
 // if (it != mymap.end())
 //   mymap.erase (it);

 dict.SetValue("URI", uri);
 dict.SetValue("ROUTE", route);

  if(route == "events") {
      sub_dict->ShowSection("NAV_EVENTS_ACTIVE");
      dict.SetValue("PAGENAME", "Kurse");
    } else if(route == "buildings") {
      sub_dict->ShowSection("NAV_BUILDINGS_ACTIVE");
      dict.SetValue("PAGENAME", "Gebäude");
    } else if(route == "lecturers") {
      sub_dict->ShowSection("NAV_LECTURERS_ACTIVE");
      dict.SetValue("PAGENAME", "Dozenten");
    } else {
        dict.SetValue("PAGENAME", "WRONG URL");
  }



  ctemplate::ExpandTemplate("templates/main.tpl", ctemplate::DO_NOT_STRIP, &dict, &output);
  return output;

}
int main(int argc, char const *argv[]) {

    // Backup the stdio streambufs
    streambuf * cin_streambuf  = cin.rdbuf();
    streambuf * cout_streambuf = cout.rdbuf();
    streambuf * cerr_streambuf = cerr.rdbuf();

    FCGX_Request request;


    FCGX_Init();
    FCGX_InitRequest(&request, 0, 0);

    while (FCGX_Accept_r(&request) == 0) {
        fcgi_streambuf cin_fcgi_streambuf(request.in);
        fcgi_streambuf cout_fcgi_streambuf(request.out);
        // fcgi_streambuf cerr_fcgi_streambuf(request.err);

        cin.rdbuf(&cin_fcgi_streambuf);
        cout.rdbuf(&cout_fcgi_streambuf);
        // cerr.rdbuf(&cerr_fcgi_streambuf);

        string uri = FCGX_GetParam("REQUEST_URI", request.envp);

        //  dict.SetValue("BODY", "<ol><li>first</li><li>second</li></ol>");

        string http_request_content = get_request_content(request);

        std::string html = renderHTML(uri, http_request_content);

        std::cout << html;

        // string content = get_request_content(request);

        // if (content.length() == 0) {
        //     content = ", World!";
        // }

        // cout << "Content-type: text/html\r\n"
        //      << "\r\n"
        //      << "<html>\n"
        //      << "  <head>\n"
        //      << "    <title>Hello, World!</title>\n"
        //      << "  </head>\n"
        //      << "  <body>\n"
        //      << "    <h1>Hello " << content << " from " << uri << " !</h1>\n"
        //      << "  </body>\n"
        //      << "</html>\n";



        // Note: the fcgi_streambuf destructor will auto flush
    }

    // restore stdio streambufs
    cin.rdbuf(cin_streambuf);
    cout.rdbuf(cout_streambuf);
    cerr.rdbuf(cerr_streambuf);

    return 0;
}
