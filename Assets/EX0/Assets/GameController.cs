using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameController : MonoBehaviour
{
    public static int FIELD_SIZE = 30; // Width and height of the game field
    public static float COLLISION_THRESHOLD = 1.5f; // Collision distance between food and player 
    public GameObject playerObject, cameraGameObject; // Reference to the Player GameObject

    private GameObject food; // Represents the food in the game
    private int score = 0;
    private Vector3 offset;
    private Transform foodT, playerT;
    // Start is called before the first frame update
    void Start()
    {
        food = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        foodT = food.GetComponent<Transform>();
        playerT = playerObject.GetComponent<Transform>();
        offset =  cameraGameObject.transform.position - playerObject.transform.position;
        SpawnFood();
    }

    // Positions the food at a random location inside the field
    void SpawnFood()
    {
        food.transform.position = new Vector3(Random.Range(-FIELD_SIZE/2, FIELD_SIZE/2),
                                               1,
                                               Random.Range(-FIELD_SIZE/2, FIELD_SIZE/2));
    }

    // Update is called once per frame
    void Update()
    {
        if (Vector3.Distance(foodT.position, playerT.position) < COLLISION_THRESHOLD)
        {
            SpawnFood();
            score++;
            Debug.Log(score);
        }
        cameraGameObject.transform.position = playerT.position + offset;
    }
}
