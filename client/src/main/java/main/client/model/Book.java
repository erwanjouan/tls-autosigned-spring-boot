package main.client.model;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;

@Data
@Getter
@Setter
public class Book {
    private long bookId;
    private String bookTitle;
    private String bookAuthor;
    private String bookPublisher;
}