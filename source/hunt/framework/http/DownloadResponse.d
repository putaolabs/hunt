module hunt.framework.http.DownloadResponse;

import std.array;
import std.conv;
import std.datetime;
import std.json;
import std.path;
import std.file;
import std.stdio;

import hunt.framework.Init;
import hunt.framework.application.AppConfig;
// import hunt.framework.http.cookie;
import hunt.framework.util.String;
import hunt.framework.Version;
import hunt.framework.http.Response;
import hunt.framework.http.Request;

import hunt.logging;

import hunt.http.codec.http.model.HttpHeader;
import hunt.http.codec.http.model.AcceptMIMEType;
import hunt.http.codec.http.model.MimeTypes;

/**
 * FileResponse represents an HTTP response delivering a file.
 */
class FileResponse : Response
{
    private string _file;
    private string _name = "undefined.file";

    this(string filename)
    {
        super(request());
        
        this.setFile(filename);
    }

    FileResponse setFile(string filename)
    {
        _file = filename;

        if (_file[0] != "/")
        {
            _file = buildPath(APP_PATH, _file);
        }

        MimeTypes mimetypes = new MimeTypes();
        string contentType = mimetypes.getMimeByExtension(_file);

        this.setMimeType(contentType);
        this.setName(baseName(fileName));
        this.loadData();
    }

    FileResponse setName(string name)
    {
        _name = name;
    }

    FileResponse setMimeType(string contentType)
    {
        setHeader(HttpHeader.CONTENT_TYPE, contentType);
    }

    FileResponse loadData()
    {
        debug logDebug("downloading file: ", _file);

        if(exists(_file) && !isDir(_file))
        {
            // setData([0x11, 0x22]);
            // FIXME: Needing refactor or cleanup -@zxp at 5/24/2018, 6:49:23 PM
            // download a huge file.
            // read file
            auto f = std.stdio.File(_file, "r");
            scope(exit) f.close();
        
            f.seek(0);
            // logDebug("file size: ", f.size);
            auto buf = f.rawRead(new ubyte[cast(uint)f.size]);
            setData(buf);
        }
        else
            throw new Exception("File does not exist: " ~ _file);

        return this;
    }

    FileResponse setData(in ubyte[] data)
    {
        setHeader(HttpHeader.CONTENT_DISPOSITION, "attachment; filename=" ~ _name ~ "; size=" ~ (to!string(data.length)));

        setContent(data);
        return this;
    }
}
