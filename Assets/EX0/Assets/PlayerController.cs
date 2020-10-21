using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    public float movementForce = 500; // Controls player movement power
    private Rigidbody body;


    // Start is called before the first frame update
    void Start()
    {
        body = GetComponent<Rigidbody>();
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.anyKey)
        {
            Vector3 dir = new Vector3();
            if (Input.GetKey(KeyCode.RightArrow))
                dir = dir + Vector3.right;
            if (Input.GetKey(KeyCode.LeftArrow))
                dir = dir - Vector3.right;
            if (Input.GetKey(KeyCode.UpArrow))
                dir = dir + Vector3.forward;
            if (Input.GetKey(KeyCode.DownArrow))
                dir = dir - Vector3.forward;
            body.AddForce(dir*Time.deltaTime* movementForce);
        }
        if (transform.position.y < -50)
            transform.position = new Vector3(0, 1, 0);
        // Implement movement logic here
    }
}
