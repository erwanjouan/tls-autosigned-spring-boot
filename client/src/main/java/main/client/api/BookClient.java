package main.client.api;

import feign.Param;
import feign.RequestLine;
import main.client.model.BookResource;

import java.util.List;

public interface BookClient {

    @RequestLine("GET /{bookId}")
    BookResource findByIsbn(@Param("bookId") String isbn);

    @RequestLine("GET")
    List<BookResource> findAll();
}
