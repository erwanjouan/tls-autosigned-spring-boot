package main.client.model;

public class BookResource {
    private Book book;

    public BookResource() {
    }

    public BookResource(Book book) {
        this.book = book;
    }

    public Book getBook() {
        return book;
    }

    public void setBook(Book book) {
        this.book = book;
    }
}
