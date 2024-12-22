import { Router } from "express";
import { auth, AuthRequest } from "../middleware/auth";
import { NewTask, tasks } from "../db/schema";
import db from "../db";
import { eq } from "drizzle-orm";


const taskRouter = Router();

taskRouter.post("/", auth, async (req: AuthRequest, res) => {
    try {

        // Create new Task
        req.body = { ...req.body, dueAt: new Date(req.body.dueAt), uid: req.user };

        const newTask: NewTask = req.body;

        const [task] = await db.insert(tasks).values(newTask).returning();

        res.status(201).json(task);

    } catch (e) {
        res.status(500).json({ msg: e });
    }
});
taskRouter.get("/", auth, async (req: AuthRequest, res) => {
    try {

        const allTask = await db.select().from(tasks).where(eq(tasks.uid, req.user!));

        res.json(allTask);

    } catch (e) {
        res.status(500).json({ msg: e });
    }
});
taskRouter.delete("/", auth, async (req: AuthRequest, res) => {
    try {

        const { taskId }: { taskId: string } = req.body

        const allTask = await db.delete(tasks).where(eq(tasks.id, taskId));

        res.json(true);

    } catch (e) {
        res.status(500).json({ msg: e });
    }
});

taskRouter.post("/sync", auth, async (req: AuthRequest, res) => {
    try {

        // req.body = { ...req.body, dueAt: new Date(req.body.dueAt), uid: req.user };

        const taskList = req.body;

        const filterdTasks: NewTask[] = [];
        for (let t of taskList) {
            t = {
                ...t, dueAt: new Date(t.dueAt), createdAt: new Date(t.createdAt), updatedAt: new Date(t.updatedAt), uid: req.user
            }
            filterdTasks.push(t);
        }
        const pushedTasks = await db.insert(tasks).values(filterdTasks).returning();

        res.status(201).json(pushedTasks);

    } catch (e) {
        res.status(500).json({ msg: e });
    }
});

export default taskRouter;