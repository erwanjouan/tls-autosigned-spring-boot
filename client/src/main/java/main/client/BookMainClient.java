package main.client;

import main.client.api.BookClient;
import main.client.api.BookClientBuilder;
import main.client.model.BookResource;

import java.util.List;

public class BookMainClient {

    public static void main(String[] args) {
        BookClient bookClient = BookClientBuilder.getBookClient();
        List<BookResource> all = bookClient.findAll();
        System.Logger logger = System.getLogger("BookMainClient");
        logger.log(System.Logger.Level.INFO, all);
    }
}
